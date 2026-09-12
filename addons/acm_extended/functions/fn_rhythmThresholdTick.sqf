/*
    Rhythm threshold guard.

    v0.9.331 design:
    - ACM remains the authority for native fatal rhythm thresholds and arrest events.
    - ACME may mirror ACM's own threshold state after a sustained threshold breach if ACM has
      not written the rhythm var yet.
    - Once native VT, PVT, VF, or Asystole appears, it is persistent. It cannot clear back to
      sinus just because HR wobbles below a threshold on the next sweep.
    - Shock/ROSC/respawn are the valid clear pathways; deterioration to a worse native rhythm
      is still allowed.
*/
if !(missionNamespace getVariable ["ACME_sys_rhythm", true]) exitWith {};  // the system toggle. fully off means this stops.
if !(missionNamespace getVariable ["ACME_rhythmThresholdsEnabled", true]) exitWith {};

private _now = CBA_missionTime;
private _acmHighHR = missionNamespace getVariable ["ACME_rhythmACMFatalHighHR", 220];
private _acmLowHR  = missionNamespace getVariable ["ACME_rhythmACMFatalLowHR", 40];
private _autoSVT = missionNamespace getVariable ["ACME_rhythmAutoSVTFromRateEnabled", false];
private _svtHR = missionNamespace getVariable ["ACME_rhythmCustomSVTHR", missionNamespace getVariable ["ACME_rhythmCriticalSVTHR", 190]];
private _svtSustain = missionNamespace getVariable ["ACME_rhythmCustomSVTSustainSec", 8];
private _shockGrace = missionNamespace getVariable ["ACME_rhythmNativeShockGraceSec", 10];

// NA3+ custom rhythms keep their target separate. Release must not copy the current
// tachycardic rate back into ACM's native target or restore an unproduced saved target.
private _fnc_releaseCustom = {
    params ["_u"];
    [_u] call ACME_fnc_rhythmRelease;
};

private _fnc_setNativeLatch = {
    params ["_u", "_kind", "_rhythm", ["_target", -1]];
    private _cur = _u getVariable ["ACME_rhythmNativeHoldKind", ""];
    if (_cur != _kind) then {
        [_u, _kind, _rhythm, true, true] call ACME_fnc_rhythmNativeHoldCommit;
        [_u, "ACME_rhythmNativeHoldSince", CBA_missionTime] call ACME_fnc_setVarNet;
        _u setVariable ["ACME_rhythmNativeClearStart", -1, false];
        if (_kind == "highVT") then {
            [_u, CBA_missionTime + (missionNamespace getVariable ["ACME_rhythmNativeHighHRFloorSec", 999999]), false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
        };
    } else {
        [_u, _kind, _rhythm, true, true] call ACME_fnc_rhythmNativeHoldCommit;
    };
    if (_target >= 0) then { [_u, _target] call ACM_circulation_fnc_setCardiacArrestTargetRhythm; };
    _u setVariable ["ACME_rhythmNativeLastSeen", CBA_missionTime, false];
};

private _fnc_clearNativeLatch = {
    params ["_u"];
    [_u, "", -1, true, true] call ACME_fnc_rhythmNativeHoldCommit;
    _u setVariable ["ACME_rhythmNativeHoldSince", -1, false];
    _u setVariable ["ACME_rhythmNativeLastSeen", -1, false];
    _u setVariable ["ACME_rhythmNativeClearStart", -1, false];
    [_u, 0, false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    _u setVariable ["ACME_rhythmThresholdForced", "", false];
};

private _fnc_thresholdStart = {
    params ["_u", "_kind"];
    private _cur = _u getVariable ["ACME_rhythmThresholdKind", ""];
    private _start = _u getVariable ["ACME_rhythmThresholdStart", -1];
    if (_cur != _kind || {_start < 0}) then {
        _u setVariable ["ACME_rhythmThresholdKind", _kind, false];
        _u setVariable ["ACME_rhythmThresholdStart", CBA_missionTime, false];
    };
};

{
    private _u = _x;
    if (isNull _u || {!alive _u} || {!local _u}) then { continue; };

    private _hr = _u getVariable ["ace_medical_heartRate", 0];
    private _rhythm = ([_u] call ACME_fnc_rhythmGet);
    private _active = _u getVariable ["ACME_rhythm_active", 0];

    private _recentShock = (!isNil "ACM_circulation_fnc_recentAEDShock" && {[_u] call ACM_circulation_fnc_recentAEDShock})
        || {_now < (_u getVariable ["ACME_rhythmNativeShockGraceUntil", 0])};
    private _roscRecent = ((_u getVariable ["ACM_circulation_ROSC_Time", -9999]) + _shockGrace) > _now;

    if (_recentShock || {_roscRecent}) then {
        [_u] call _fnc_clearNativeLatch;
        _u setVariable ["ACME_rhythmThresholdStart", nil];
        _u setVariable ["ACME_rhythmThresholdKind", ""];
        continue;
    };

    // Lidocaine benefit follows ACM's current medication effect. B14 deliberately removed the old long-lived
    // therapeutic latch, so do not retain a read of ACME_rhythm_lidoLastTherapeutic: nothing writes it anymore.
    // Clean units skip the cardiac-medication-effects lookup; any active lidocaine remains represented in ACE's
    // medication array for the duration of its effect.
    private _lidoEff = 0;
    if (count (_u getVariable ["ace_medical_medications", []]) > 0) then {
        _lidoEff = [_u] call ACME_fnc_lidoEffectiveness;
    };

    // therapeutic lidocaine on board deterministically terminates monomorphic vt-with-pulse, native rhythm 4, back to
    // sinus. vf and pulseless vt are arrest rhythms, so lidocaine raises their defibrillation odds instead, see
    // fn_aedButtonShock, and it does not spontaneously convert an arrest rhythm.
    if (_lidoEff > 0 && {_rhythm == 4} && {!(_u getVariable ["ace_medical_inCardiacArrest", false])}) then {
        [_u, 0] call ACME_fnc_rhythmSet;  // sinus.
        [_u, 0] call ACM_circulation_fnc_setCardiacArrestTargetRhythm;
        [_u] call _fnc_clearNativeLatch;
        if (_active >= 100) then { [_u, false] call _fnc_releaseCustom; };
        [_u, [["aedPadsLastSync", -1]], true] call ACM_circulation_fnc_setRuntimeState;  // refresh the monitor now.
        _u setVariable ["ACME_rhythmThresholdStart", nil];
        _u setVariable ["ACME_rhythmThresholdKind", ""];
        continue;
    };

    // if a native critical rhythm exists, latch it. deterioration to a worse native rhythm is allowed and spontaneous
    // clearing to sinus or PEA is not.
    if (_rhythm in [1, 2, 3, 4]) then {
        if (_active >= 100) then { [_u, false] call _fnc_releaseCustom; };
        switch (_rhythm) do {
            case 4: { [_u, "highVT", 4, 3] call _fnc_setNativeLatch; };
            case 3: { [_u, "pvt", 3, 3] call _fnc_setNativeLatch; };
            case 2: { [_u, "vf", 2, 2] call _fnc_setNativeLatch; };
            case 1: { [_u, "asystole", 1, 1] call _fnc_setNativeLatch; };
        };
    };

    // B67 authority boundary: ACME no longer creates VT/asystole or enters cardiac arrest merely because the
    // observed HR crossed ACM's native fatal thresholds. ACM's handleUnitVitals/medical state machine is the one
    // authority for those transitions. ACME only observes and latches a native rhythm AFTER ACM creates it. This
    // removes the former 1.25 s fallback race that could independently re-arrest a recent ROSC patient.
    private _legacyThresholdKind = _u getVariable ["ACME_rhythmThresholdKind", ""];
    if (_legacyThresholdKind in ["high", "low"]) then {
        _u setVariable ["ACME_rhythmThresholdStart", nil];
        _u setVariable ["ACME_rhythmThresholdKind", ""];
        if ((_u getVariable ["ACME_rhythmThresholdForced", ""]) in ["ACM VT fallback", "ACM low-HR fallback"]) then {
            [_u, "ACME_rhythmThresholdForced", ""] call ACME_fnc_setVarNet;
        };
    };

    private _holdKind = _u getVariable ["ACME_rhythmNativeHoldKind", ""];
    if (_holdKind != "") then {
        private _heldRhythm = _u getVariable ["ACME_rhythmNativeHoldRhythm", -1];
        _rhythm = ([_u] call ACME_fnc_rhythmGet);

        // B21: a VT that WE created only as the fallback for a transient >220 bpm threshold is not an immortal
        // diagnosis. B20 deliberately latched every native VT forever, which produced the reported broad VT/PVT
        // waveform at a recovered rate around 129 bpm. Preserve true/native VT and every arrest rhythm, but if this
        // exact latch was source-tagged by the threshold fallback, the patient is still perfusing, and HR stays
        // safely below the recovery ceiling for several seconds, hand the patient back to sinus. If the catecholamine
        // surge is still present, the pressor-surge gate can then induce the intended A-tach/SVT instead.
        if (_holdKind == "highVT"
            && {_heldRhythm == 4}
            && {!(_u getVariable ["ace_medical_inCardiacArrest", false])}
            && {(_u getVariable ["ACME_rhythmThresholdForced", ""]) == "ACM VT fallback"}) then {
            private _recoverHR = missionNamespace getVariable ["ACME_rhythmNativeVTRecoverHR", 200];
            private _recoverSec = missionNamespace getVariable ["ACME_rhythmNativeVTRecoverSec", 6];
            if (_hr < _recoverHR) then {
                private _clearStart = _u getVariable ["ACME_rhythmNativeClearStart", -1];
                if (_clearStart < 0) then {
                    _u setVariable ["ACME_rhythmNativeClearStart", _now, false];
                } else {
                    if ((_now - _clearStart) >= _recoverSec) then {
                        [_u, 0] call ACME_fnc_rhythmSet;
                        [_u] call _fnc_clearNativeLatch;
                        [_u, [["aedPadsLastSync", -1]], true] call ACM_circulation_fnc_setRuntimeState;
                        continue;
                    };
                };
            } else {
                _u setVariable ["ACME_rhythmNativeClearStart", -1, false];
            };
        };

        // allow deterioration to more lethal native rhythms and update the latch to match.
        if (_rhythm in [1, 2, 3, 4] && {_rhythm != _heldRhythm}) then {
            switch (_rhythm) do {
                case 4: { [_u, "highVT", 4, 3] call _fnc_setNativeLatch; };
                case 3: { [_u, "pvt", 3, 3] call _fnc_setNativeLatch; };
                case 2: { [_u, "vf", 2, 2] call _fnc_setNativeLatch; };
                case 1: { [_u, "asystole", 1, 1] call _fnc_setNativeLatch; };
            };
            continue;
        };

        // do not let vt, vf, PVT or asystole silently clear to sinus or PEA.
        if (!(_rhythm in [1, 2, 3, 4]) && {_heldRhythm in [1,2,3,4]}) then {
            [_u, _heldRhythm] call ACME_fnc_rhythmSet;
            switch (_heldRhythm) do {
                case 4: { [_u, 3] call ACM_circulation_fnc_setCardiacArrestTargetRhythm; };
                case 3: { [_u, 3] call ACM_circulation_fnc_setCardiacArrestTargetRhythm; };
                case 2: { [_u, 2] call ACM_circulation_fnc_setCardiacArrestTargetRhythm; };
                case 1: { [_u, 1] call ACM_circulation_fnc_setCardiacArrestTargetRhythm; };
            };
            [_u, "ACME_rhythmThresholdForced", "native persistent hold"] call ACME_fnc_setVarNet;
        };
        continue;
    };

    _u setVariable ["ACME_rhythmThresholdStart", nil];
    _u setVariable ["ACME_rhythmThresholdKind", ""];

    // an orphan sweep. hr is in the normal band, not over the fatal-high line and not under the fatal-low line, and no
    // native rhythm is latched, and yet the display still holds one of our custom codes, 100 or above, with no custom
    // tick managing it, because rhythm_active is 0. that is the stuck state where the QRS keeps showing with no hr
    // number and no pulse, and it arises when an SVT into vt handoff is interrupted before vt latches. hand it back to
    // sinus so ACM owns a rhythm it understands, and the surge inducer can then re-arm SVT, or a renewed hr climb
    // re-latches vt cleanly.
    if (_active == 0 && {(([_u] call ACME_fnc_rhythmGet)) >= 100}) then {
        [_u, 0] call ACME_fnc_rhythmSet;
        [_u, [["aedPadsLastSync", -1]], true] call ACM_circulation_fnc_setRuntimeState;  // force the monitor to redraw now.
        continue;
    };

    if (!_autoSVT) then { continue; };
    if (_active != 0 || {!(_rhythm in [0, 5])}) then { continue; };

    private _thresholdState = "";
    if (_hr >= _svtHR && {_hr <= _acmHighHR}) then { _thresholdState = "svt"; };
    if (_thresholdState == "") then { continue; };

    private _cur = _u getVariable ["ACME_rhythmThresholdKind", ""];
    private _start = _u getVariable ["ACME_rhythmThresholdStart", -1];
    if (_cur != _thresholdState || {_start < 0}) then {
        _u setVariable ["ACME_rhythmThresholdKind", _thresholdState, false];
        _u setVariable ["ACME_rhythmThresholdStart", _now, false];
        continue;
    };
    if ((_now - _start) < _svtSustain) then { continue; };

    [objNull, _u, 104, "SVT", (_hr min _acmHighHR)] call ACME_fnc_rhythmToggle;
    [_u, "ACME_rhythmThresholdForced", "SVT"] call ACME_fnc_setVarNet;
} forEach allUnits;
