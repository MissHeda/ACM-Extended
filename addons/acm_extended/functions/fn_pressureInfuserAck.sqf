/* Medic-owner acknowledgement. A late or duplicate reply cannot return another item. */
params ["_id", "_ok", "_refund", "_message"];
private _pending = missionNamespace getVariable ["ACME_piPending", createHashMap];
private _entry = _pending getOrDefault [_id, []];
if (_entry isEqualTo [] || {_entry select 3}) exitWith {};
private _args = _entry select 1;
private _medic = _args select 1;
if (isNull _medic || {!local _medic}) exitWith {};
_entry set [3, true];
_pending set [_id, _entry];
missionNamespace setVariable ["ACME_piPending", _pending];
if (_refund && {_args select 6}) then {[_medic, "ACME_PressureInfuser"] call ace_common_fnc_addToInventory;};
[_medic, _message] call ACME_fnc_clinicalNotice;
if (_ok && {!isNull (_entry select 0)}) then {
    [_entry select 0, "activity", _message, []] call ace_medical_treatment_fnc_addToLog;
};
