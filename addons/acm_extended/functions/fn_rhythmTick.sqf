// Sustain custom-rhythm symptoms on the patient owner. updateHeartRate consumes the separate rhythm target;
// this tick never pins native rhythm state or directly forces HR. A real native deterioration releases the
// overlay. A fast supraventricular rate alone does not change its electrical origin.
// Release removes Extended contributions and ends its temporary obtundation without overwriting native state.
if !(missionNamespace getVariable ["ACME_sys_rhythm", true]) exitWith {};
private _fnc_release = {params ["_u"]; [_u] call ACME_fnc_rhythmRelease;};

{
    private _u = _x;
    private _code = _u getVariable ["ACME_rhythm_active", 0];

    // physiology takes over, so let the rhythm change. if the patient has entered cardiac arrest, or ACM's own sim
    // has moved the display rhythm to an arrest or CPR rhythm, meaning asystole, vf, pulseless vt, PEA or CPR, or
    // the heart rate has cratered, we stop forcing and hand the monitor back to ACM. this both honors a real
    // deterioration, such as a hypoxic arrest while AFib-RVR is induced, and avoids drawing an organized forced
    // rhythm at hr 0, which makes ACM divide 60 by hr and gives the zero divisor crash in displayaedmonitor and
    // genekg.
    private _curRhythm = [_u] call ACME_fnc_rhythmNative;
    private _dt = [_u, "rhythm", 0.5, 5] call ACME_fnc_clinicalTickDelta;
    private _hrNow = _u getVariable ["ace_medical_heartRate", 80];

    // Torsades uses the native pulseless-VT contract. Every other custom perfusing rhythm yields immediately at
    // ACM's own fatal-rate boundaries. This prevents an AFib/SVT overlay from masking the native >220 VT/PVT or
    // <40 VF/asystole transition that handleUnitVitals has already selected.
    private _isTorsades = (_code == 102);
    private _hrReleases = !_isTorsades && {
        (_hrNow < (missionNamespace getVariable ["ACME_rhythmACMFatalLowHR", 40]))
        || {_hrNow > (missionNamespace getVariable ["ACME_rhythmACMFatalHighHR", 220])}
    };
    // for torsades, its own PVT proxy, 3, is expected and must not count as having moved to an arrest rhythm. exclude
    // 3 from the arrest-list trigger while in torsades, and every other arrest and CPR code still releases it.
    private _arrestList = if (_isTorsades) then { [-1, 1, 2, 4, 5] } else { [-1, 1, 2, 3, 4, 5] };
    private _physiologyTookOver = ((_u getVariable ["ace_medical_inCardiacArrest", false]) != _isTorsades)
        || {_curRhythm in _arrestList}
        || _hrReleases;

    if (_physiologyTookOver) then {
        [_u, false] call _fnc_release;
    } else {
        // the hemodynamic profile: each rhythm presents with its real-life perfusion picture.
        // bpoffset drops MAP, which cascades everywhere downstream: a low NIBP on the cuff, a prolonged capillary refill,
        // because ACM's crt is a function of MAP and blood volume, the obtunded auto-band, and a low CPP on a TBI brain.
        // a poorly perfusing rhythm therefore reads as one without us touching each vital by hand. spo2floor adds
        // peripheral desaturation for the unstable rhythms, and it is skipped while an NRB is feeding o2.
        private _bpOff = switch (_code) do {
            case 100: { missionNamespace getVariable ["ACME_rhythm_bpDropRVR", -28] };  // AFib-RVR: unstable and poorly perfusing.
            case 101: { missionNamespace getVariable ["ACME_rhythm_bpDropAtrialTach", -12] };  // atrial tach: mild instability.
            case 102: { missionNamespace getVariable ["ACME_rhythm_bpDropTorsades", -30] };  // torsades: near-arrest.
            case 103: { missionNamespace getVariable ["ACME_rhythm_bpDropAFib", 0] };  // controlled AFib: it perfuses fine.
            case 104: { missionNamespace getVariable ["ACME_rhythm_bpDropSVT", -18] };  // SVT: symptomatic and cardiovertible.
            default  { 0 };
        };
        if ((_u getVariable ["ACME_rhythm_bpOffset", 0]) != _bpOff) then { [_u, "ACME_rhythm_bpOffset", _bpOff] call ACME_fnc_setVarNet; };

        private _spo2Floor = switch (_code) do {
            case 100: { 90 }; case 102: { 88 }; case 104: { 93 }; case 101: { 95 }; default { 100 };
        };
        if (_spo2Floor < 100 && {!(_u getVariable ["ACME_nrb_delivering", false])}) then {
            private _spo2 = _u getVariable ["ace_medical_spo2", 97];
            if (_spo2 > _spo2Floor) then { [_u, [["spo2", ((_spo2 - (1.2 * _dt)) max _spo2Floor), true, true]]] call ACM_core_fnc_setAceMedicalState; };
        };

        private _targetPain = switch (_code) do {
            case 100: {missionNamespace getVariable ["ACME_rhythm_painRVR", 0.50]};
            case 101: {missionNamespace getVariable ["ACME_rhythm_painAtrialTach", 0.35]};
            case 103: {missionNamespace getVariable ["ACME_rhythm_painAFib", 0.35]};
            case 104: {missionNamespace getVariable ["ACME_rhythm_painSVT", 0.45]};
            default {0};
        };
        // Separate perceived discomfort. Native wounds and analgesic history remain untouched.
        private _cur = _u getVariable ["ACME_rhythm_painContribution", 0];
        private _step = (missionNamespace getVariable ["ACME_rhythm_painStepPerSec", 0.12]) * _dt;
        if (_u getVariable ["ACE_isUnconscious", false]) then {_targetPain = 0;};
        [_u, "ACME_rhythm_painContribution", _cur + (((_targetPain - _cur) max (-_step)) min _step)] call ACME_fnc_setVarNet;
        if (_code != 102) then {
            // an obtundation episode: a chance per tick to drop into the lying state, player-only, because obtundedset wakes
            // an unconscious patient into it. it uses a manual flag, so the vitals-driven auto-evaluator leaves it alone,
            // and we end it on our own timer.
            if (isPlayer _u) then {
                if (!(_u getVariable ["ACME_obtunded", false])) then {
                    if (random 1 < (1 - ((1 - (missionNamespace getVariable ["ACME_rhythm_obtundChancePerTick", 0.015])) ^ (_dt / 0.5)))) then {
                        private _lo = missionNamespace getVariable ["ACME_rhythm_obtundMinSec", 12];
                        private _hi = missionNamespace getVariable ["ACME_rhythm_obtundMaxSec", 30];
                        [_u, "ACME_rhythm_obtundUntil", (CBA_missionTime + _lo + random (_hi - _lo))] call ACME_fnc_setVarNet;
                        [_u, true, true] call ACME_fnc_obtundedSet;
                    };
                } else {
                    // end the episode when its timer runs out, and only if we started it.
                    private _until = _u getVariable ["ACME_rhythm_obtundUntil", -1];
                    if (_until > 0 && {CBA_missionTime >= _until}) then {
                        [_u, "ACME_rhythm_obtundUntil", -1] call ACME_fnc_setVarNet;
                        [_u, false, false] call ACME_fnc_obtundedSet;
                    };
                };
            };
        };


    };
} forEach (allUnits select {local _x && {alive _x} && {(_x getVariable ["ACME_rhythm_active", 0]) >= 100}});
