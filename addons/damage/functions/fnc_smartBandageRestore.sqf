#include "..\script_component.hpp"
/* Restore reserved supplies after a cancelled/invalid smart-bandage transaction. */
params ["_medic", ["_txn", []]];
if (_txn isEqualTo []) exitWith {};
private _reserved = _txn param [3, []];
{
    _x params ["_owner", "_item"];
    private _dst = if (!isNull _owner) then {_owner} else {_medic};
    if (!isNull _dst) then {[_dst, _item] call ace_common_fnc_addToInventory;};
} forEach _reserved;
if (!isNull _medic) then {_medic setVariable [QGVAR(smartBandageTxn), [], false];};
