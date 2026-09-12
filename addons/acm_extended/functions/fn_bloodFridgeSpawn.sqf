// the server-side spawn of a stocked blood fridge from a resolved spec. it is shared by eden placement, the zeus
// popup confirm and any scripted placement.
// call it as [_pos, _dir, _stock, _restock, _regenMins] call ACME_fnc_bloodFridgeSpawn.
// _stock is [[bloodclass, count], ...]. _regenMins is the per-fridge interval override, where -1 uses the global
// and 0 is never.
params ["_pos", "_dir", ["_stock", []], ["_restock", true], ["_regenMins", -1]];
if (!isServer) exitWith {};

private _closed = createVehicle ["ACME_BloodFridge_Closed", _pos, [], 0, "CAN_COLLIDE"];
_closed setDir _dir;
_closed setPosATL _pos;
[_closed, _stock, _restock] call ACME_fnc_bloodFridgeSetup;
_closed setVariable ["ACME_bf_regenMins", _regenMins, true];
_closed
