/* ACM procedure callback, adapted by ACM Extended B35.
   Completion logs stay in the native public entry. Body posture does not cause
   delayed tube failure. Closing drainage preserves any residual pleural injury. */
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACM_breathing_Thoracostomy_resealChestTubeLocal", _this, _patient] call CBA_fnc_targetEvent;
};
[_patient] call ACME_fnc_ptxEnsure;

_patient setVariable ["ACM_breathing_Thoracostomy_State", 2, true];
[_patient, "tube"] call ACME_fnc_ptxTreat;
[_patient] call ACM_breathing_fnc_updateLungState;
