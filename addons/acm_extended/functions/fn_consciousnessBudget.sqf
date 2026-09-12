// the casualty consciousness budget: the hard backstop against a black-screen simulator.
// it runs periodically on local alive players. the obtunded auto-evaluator already pops a casualty out of true ko
// into the obtunded band the moment their vitals climb into it, at the wake floor, and this adds the time cap so
// no single continuous ko stretch exceeds ACME_ko_mercySeconds.
// when the cap is hit we open a mercy hold: for ACME_ko_mercyHoldSeconds we keep the casualty awake-but-down, in
// back-stuck obtundation, whatever the vitals, re-asserting each tick against ACE's re-ko and pinning the SpO2
// and pain to the wake floor so it sticks. it is a gameplay mercy: you have been worked on long enough to be
// groggy-awake rather than out.
// after the hold, the normal rules resume: if the vitals are still ko-level they crash again, which is a fresh
// stretch. so the worst case is one mercy window of black, never a 15-minute void.
// cardiac arrest is never held, because that is CPR and ROSC territory, the one state where black is honest.
if !(missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith {};
if !(missionNamespace getVariable ["ACME_ko_systemEnable", true]) exitWith {};

private _mercy    = missionNamespace getVariable ["ACME_ko_mercySeconds", 300];
private _hold     = missionNamespace getVariable ["ACME_ko_mercyHoldSeconds", 45];
private _wakeSpO2 = missionNamespace getVariable ["ACME_ko_wakeFloorSpO2", 85];
private _painCap  = missionNamespace getVariable ["ACME_ko_wakePainCap", 0.5];
private _now = CBA_missionTime;

{
    private _u = _x;
    private _ko        = _u getVariable ["ACE_isUnconscious", false];
    private _arrest    = _u getVariable ["ace_medical_inCardiacArrest", false];
    private _holdUntil = _u getVariable ["ACME_ko_holdUntil", 0];

    if (_now < _holdUntil && {!_arrest}) then {
        // the mercy hold: only act if ACE tried to re-ko them. otherwise leave the posture to the auto-evaluator.
        if (_ko) then {
            if ((_u getVariable ["ace_medical_spo2", 97]) < _wakeSpO2) then { [_u, [["spo2", _wakeSpO2, true, true]]] call ACM_core_fnc_setAceMedicalState; };
            if ((_u getVariable ["ace_medical_pain", 0]) > _painCap)  then { [_u, [["pain", _painCap, true, true]]] call ACM_core_fnc_setAceMedicalState; };
            [_u, true, false, "back"] call ACME_fnc_obtundedSet;  // re-wake into back-stuck.
        };
    } else {
        if (_ko && {!_arrest}) then {
            private _since = _u getVariable ["ACME_ko_since", -1];
            if (_since < 0) then { _since = _now; [_u, "ACME_ko_since", _now] call ACME_fnc_setVarNet; };
            if ((_now - _since) >= _mercy) then {
                // open the hold window, plus an immediate wake.
                if ((_u getVariable ["ace_medical_spo2", 97]) < _wakeSpO2) then { [_u, [["spo2", _wakeSpO2, true, true]]] call ACM_core_fnc_setAceMedicalState; };
                if ((_u getVariable ["ace_medical_pain", 0]) > _painCap)  then { [_u, [["pain", _painCap, true, true]]] call ACM_core_fnc_setAceMedicalState; };
                [_u, true, false, "back"] call ACME_fnc_obtundedSet;
                [_u, "ACME_ko_holdUntil", _now + _hold] call ACME_fnc_setVarNet;
                [_u, "ACME_ko_since", -1] call ACME_fnc_setVarNet;// the hold owns it now, and a post-hold crash is a fresh stretch.
            };
        } else {
            if ((_u getVariable ["ACME_ko_since", -1]) >= 0) then { [_u, "ACME_ko_since", -1] call ACME_fnc_setVarNet; };
        };
    };
} forEach (allUnits select {local _x && {alive _x} && {isPlayer _x}});
