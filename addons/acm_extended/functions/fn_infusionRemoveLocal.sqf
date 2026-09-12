/* Identified owner-side deletion. Settle already-admitted pending drug; never delete native medication history. */
params ["_patient", "_medic", "_bagUid", "_epoch"];
if (!local _patient || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {};
private _map = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _part = ""; private _index = -1;
{private _i = _y findIf {(_x param [8, ""]) == _bagUid}; if (_i >= 0) exitWith {_part = _x; _index = _i;};} forEach _map;
if (_index < 0) exitWith {};
[_patient, _bagUid] call ACME_fnc_infusionRetire;
private _arr = _map get _part; _arr deleteAt _index; _map set [_part, _arr];
[_patient, _map, true] call ACME_fnc_ivBagsCommit;
[_patient, _part] call ACM_circulation_fnc_updateActiveFluidBags;
[_medic, "Infusion removed and discarded. Previously delivered medication remains active."] call ACME_fnc_clinicalNotice;
