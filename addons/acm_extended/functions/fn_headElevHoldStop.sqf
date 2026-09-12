/* The continuous-action worker owns animation and key-handler cleanup. */
params ["_medic", "_patient", "_token"];
if (!local _medic) exitWith {[_medic, "headElevHoldStop", _this] call ACME_fnc_ownerDispatch;};
if ((_medic getVariable ["ACME_headElev_holding", []]) isEqualTo [_patient, _token]) then {
    ACM_core_ContinuousAction_Active = false;
};
