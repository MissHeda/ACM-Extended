#include "..\script_component.hpp"
params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {};
private _txn = _medic getVariable [QGVAR(smartBandageTxn), []];
if (_txn isEqualTo [] || {!((_txn param [0, objNull]) isEqualTo _patient)} || {(_txn param [1, ""]) != toLowerANSI _bodyPart}) exitWith {};
private _plan = _txn param [2, []];
private _treatments = _plan apply {_x select 0};
[QGVAR(smartBandageApplyLocal), [_patient, _bodyPart, _treatments], _patient] call CBA_fnc_targetEvent;
_medic setVariable [QGVAR(smartBandageTxn), [], false];
[_patient, "activity", "%1 bandaged multiple wounds (%2 dressings)", [[_medic, false, true] call ace_common_fnc_getName, count _plan]] call ace_medical_treatment_fnc_addToLog;
