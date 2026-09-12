/* ACM chest-seal owner callback, adapted by ACM Extended B35.
   Keep native equipment state; residual pneumothorax is governed by the shared model. */
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACM_breathing_applyChestSealLocal", _this, _patient] call CBA_fnc_targetEvent;
};
[_patient] call ACME_fnc_ptxEnsure;

_patient setVariable ["ACM_breathing_ChestSeal_State", true, true];
[_patient, "seal"] call ACME_fnc_ptxTreat;
[_patient] call ACM_breathing_fnc_updateLungState;
