/* ACM needle-decompression owner callback, adapted by ACM Extended B35.
   Relief and persistent catheter drainage use one model. An unindicated pleural
   puncture remains an actual new injury; it never queues unconditional tension. */
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACM_breathing_performNCDLocal", _this, _patient] call CBA_fnc_targetEvent;
};
[_patient] call ACME_fnc_ptxEnsure;

[_patient, 0.5] call ace_medical_fnc_adjustPainLevel;
private _indicated = (_patient getVariable ["ACM_breathing_Pneumothorax_State", 0]) > 0
    || {_patient getVariable ["ACM_breathing_TensionPneumothorax_State", false]};
if (!_indicated) then {
    [_patient, 1] call ACME_fnc_ptxInjury;
    _patient setVariable ["ACME_ncd_iatrogenic", true, true];
    _patient setVariable ["ACME_ncd_unindicatedCount", (_patient getVariable ["ACME_ncd_unindicatedCount", 0]) + 1, true];
};
[_patient, "ncd"] call ACME_fnc_ptxTreat;
[_patient] call ACM_breathing_fnc_updateLungState;
