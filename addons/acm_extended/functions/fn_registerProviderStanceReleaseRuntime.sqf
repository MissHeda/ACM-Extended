// B72 provider stance release. ACME starts ordinary on-foot treatments from empty-hands crouch, but setUnitPos is
// only an entry guard, never a permanent player lock. Once ACE reports success/failure, release AUTO after the
// native crouched end-animation handoff. Do not interfere with head-lift or another ACME-owned finite pose.
//
// Direct Pressure integration: another treatment owns the provider animation the instant ACE says it started.
// Retire DP's held-animation generation at that boundary so a tourniquet, bandage, IV action, etc. can never be
// overwritten by the short ACME_DirectPressureHold reassert worker. Limb/head DP remains clinically active and
// simply yields its pose to movement/treatments; torso DP is the exclusive maneuver and movement hard-releases it.
["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (hasInterface && {!isNil "ACE_player"} && {_medic isEqualTo ACE_player}
        && {uiNamespace getVariable ["ACME_PulseCheckActive", false]}) then {
        uiNamespace setVariable ["ACME_PulseCheckCancel", true];
        "ACM_FeelPulse" cutText ["","PLAIN",0,false];
    };
    if (isNull _medic || {!local _medic} || {!(_medic getVariable ["ACME_DP_Active", false])}) exitWith {};
    if (_classname == "ACME_DirectPressure") exitWith {};
    if !((_medic getVariable ["ACME_DP_Patient", objNull]) isEqualTo _patient) exitWith {};

    // A normal treatment owns provider animation until ACE reports success/failure. DP remains clinically active,
    // but its visual hold becomes completely passive so it cannot overwrite the intervention animation.
    _medic setVariable ["ACME_DP_TreatmentBusy", true, false];
    _medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];
    _medic setVariable ["ACME_DP_InPose", false];
    _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
    _medic setVariable ["ACME_DP_LastPoseAssert", 0];
}] call CBA_fnc_addEventHandler;

{
    [_x, {
        params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
        if (isNull _medic || {!local _medic} || {!alive _medic} || {!isNull objectParent _medic}) exitWith {};

        private _classKey = toLowerANSI _classname;
        private _headOwned = _classname in ["ACME_ElevateHead", "ACME_LowerHead"];
        // CheckPulse is intentionally a near-instant ACE treatment whose success callback opens ACME's longer-lived
        // pulse/watch minigame. ACE emits ace_treatmentSucceded only AFTER that callback returns. If the generic DP
        // completion path clears TreatmentBusy and reopens the medical menu here, it immediately destroys the pulse
        // minigame that just started. Keep DP animation-passive until fnc_feelPulse performs its real cleanup.
        private _pulseStillOwnsProvider = (_classKey == "checkpulse")
            && {uiNamespace getVariable ["ACME_PulseCheckActive", false]}
            && {(uiNamespace getVariable ["ACME_PulseCheckMedic", objNull]) isEqualTo _medic}
            && {(uiNamespace getVariable ["ACME_PulseCheckPatient", objNull]) isEqualTo _patient};

        // A completed/failed treatment gets a fresh quiet window before Direct Pressure is allowed to visibly resume.
        // Head positioning is the exception: its provider sequence continues after the ACE event, so a successful
        // active sequence keeps the clinical pause until fn_headElevMedicSeq reaches its real end state.
        if ((_medic getVariable ["ACME_DP_Active", false])
            && {(_medic getVariable ["ACME_DP_Patient", objNull]) isEqualTo _patient}) then {
            private _pauseClass = _medic getVariable ["ACME_DP_PauseTreatmentClass", ""];
            private _headStillActive = _headOwned && {_medic getVariable ["ACME_headElev_seqActive", false]};
            if (_pauseClass != "" && {_pauseClass == _classKey} && {!_headStillActive}) then {
                _medic setVariable ["ACME_DP_Paused", false, false];
                _medic setVariable ["ACME_DP_PauseTreatmentClass", "", false];
            };
            if (!_headStillActive && {!_pulseStillOwnsProvider}) then {
                _medic setVariable ["ACME_DP_TreatmentBusy", false, false];
                _medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];
                _medic setVariable ["ACME_DP_InPose", false];
                _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
                _medic setVariable ["ACME_DP_LastPoseAssert", 0];

                // DP treatments always return to the same casualty's medical menu. ACE's native pendingReopen does
                // this in the normal case; this guarded fallback covers the preflight path without altering global
                // menu behavior for any other intervention.
                [{
                    params ["_m", "_p"];
                    if (isNull _m || {isNull _p} || {!local _m}
                        || {!(_m getVariable ["ACME_DP_Active", false])}
                        || {!((_m getVariable ["ACME_DP_Patient", objNull]) isEqualTo _p)}) exitWith {};
                    private _menu = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
                    private _progress = uiNamespace getVariable ["ace_common_dlgProgress", displayNull];
                    if (isNull _menu && {isNull _progress}) then {
                        ["ACM_core_openMedicalMenu", _p] call CBA_fnc_localEvent;
                    };
                }, [_medic, _patient], 0.05] call CBA_fnc_waitAndExecute;
            };
        };

        if (_headOwned) exitWith {};

        [{
            params ["_m"];
            if (isNull _m || {!local _m} || {!alive _m} || {!isNull objectParent _m}) exitWith {};
            if ((_m getVariable ["ACME_treatmentPoseState", []]) isNotEqualTo []
                || {_m getVariable ["ACME_rollProviderActive", false]}
                || {_m getVariable ["ACME_headElev_seqActive", false]}) exitWith {};
            _m setUnitPos "AUTO";
        }, [_medic], 0.12] call CBA_fnc_waitAndExecute;
    }] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];

// Zone 3 posture control must distinguish a treatment animation from a genuine attempt to stand. These events
// originate on the provider's client, so publish a short patient timestamp that the owner-local AAJT watcher reads.
["ace_treatmentStarted", {
    params ["_medic", "_patient"];
    if (isNull _patient || {!(_patient getVariable ["ACME_AAJT_zone3", false])}) exitWith {};
    _patient setVariable ["ACME_AAJT_treatmentGraceUntil", CBA_missionTime + 120, true];
}] call CBA_fnc_addEventHandler;
{
    [_x, {
        params ["_medic", "_patient"];
        if (isNull _patient || {!(_patient getVariable ["ACME_AAJT_zone3", false])}) exitWith {};
        _patient setVariable ["ACME_AAJT_treatmentGraceUntil", CBA_missionTime + 0.9, true];
    }] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];

