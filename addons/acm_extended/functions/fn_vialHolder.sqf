/* Resolve the inventory object that owns the currently selected Narc Box vial stock.
   B43 fail-safe: native ACM initializes the selector to Self, but a stale/invalid patient or vehicle
   selection must never turn the entire medication list into ghost 0.00 mL / x00 rows.  If the
   requested source no longer exists, fall back to the medic and normalize the selector to Self.
*/
params [['_medic', objNull, [objNull]], ['_selection', -1, [0]]];
if (isNull _medic) exitWith {objNull};
if (_selection < 0) then {
    _selection = missionNamespace getVariable ['ACM_circulation_SyringeDraw_InventorySelection', 0];
};

private _holder = switch (_selection) do {
    case 1: {missionNamespace getVariable ['ACM_circulation_SyringeDraw_Target', objNull]};
    case 2: {objectParent _medic};
    default {_medic};
};

// Mirror ACM's own inventory-switch fail-safe.  A stale patient/vehicle source is not a valid reason
// to make a medic's own carried vials disappear.
if (isNull _holder) then {
    _holder = _medic;
    if (_selection != 0) then {
        [["syringeDrawInventorySelection", 0]] call ACM_circulation_fnc_setLocalUiState;
    };
};

_holder
