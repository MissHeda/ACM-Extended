// a debug toggle: turn a true cheyne-stokes respiratory pattern on or off on the target. it is independent of the
// TBI, so it can be demonstrated on any casualty.
// when on, the patient is added to ACME_cs_activePatients and fn_cheynestokestick drives a crescendo-decrescendo
// breathing cycle, with an apneic pause, into ACM_breathing_RespirationRate, which the check breathing of the
// medic reads and the capnography of ACM, the EtCO2, follows. toggling off restores the saved rr.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith { ["ACME_ownerCommand", [_patient, "cheyne", _this], _patient] call CBA_fnc_targetEvent; };

private _on = _patient getVariable ["ACME_cs_active", false];

if (_on) then {
    // turn off: restore the pre-cheyne-stokes respiration target and drop from the driver list.
    _patient setVariable ["ACME_cs_active", false, true];
    _patient setVariable ["ACME_cs_rrDrive", -1, true];  // release the rr drive so the override stops pinning
    if !(isNil {_patient getVariable "ACME_cs_savedRR"}) then {
        private _saved = _patient getVariable ["ACME_cs_savedRR", 16];
        _patient setVariable ["ACME_cs_savedRR", nil, true];
    };
    private _list = missionNamespace getVariable ["ACME_cs_activePatients", []];
    _list = _list - [_patient];
    missionNamespace setVariable ["ACME_cs_activePatients", _list, false];
    ["Cheyne-Stokes respirations OFF", 2, _medic] call ACME_fnc_netNotice;
} else {
    // turn on: save the current rr, seed the cycle and add to the driver list.
    if (isNil {_patient getVariable "ACME_cs_savedRR"}) then {
        _patient setVariable ["ACME_cs_savedRR", (_patient getVariable ["ACM_core_TargetVitals_RespirationRate", 16]), true];
    };
    _patient setVariable ["ACME_cs_active", true, true];
    _patient setVariable ["ACME_cs_cycleStart", CBA_missionTime, true];
    private _list = missionNamespace getVariable ["ACME_cs_activePatients", []];
    _list pushBackUnique _patient;
    missionNamespace setVariable ["ACME_cs_activePatients", _list, false];
    ["Cheyne-Stokes respirations ON.", 3, _medic] call ACME_fnc_netNotice;
};
