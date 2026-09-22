/* Call only after the pending request is marked acknowledged. */
params [["_receipt", [], [[]]]];
if (_receipt isEqualTo []) exitWith {};
_receipt params ["_medic", ["_items", []], ["_solution", []]];
if (isNull _medic || {!local _medic}) exitWith {};
{[_medic, _x] call ace_common_fnc_addToInventory;} forEach _items;
if (count _solution == 2) then {
    _solution params ["_med", "_ml"];
    [_medic, _med, _ml, _medic] call ACME_fnc_vialRefund;
};
