// the client-side initiator, run from the statement of the take action. it asks the owning machine of the fridge to
// dispense one unit.
// the owner is authoritative over the stock count, so the decrement and the actual give happen there, or through
// it, to avoid two clients taking the last unit. the owner then targetevents the unit into the inventory of this
// player.
// _this is [_anchor, _class, _player].
params ["_anchor", "_class", "_player"];
if (isNull _anchor || isNull _player) exitWith {};
["ACME_bfTake", [_anchor, _class, _player], _anchor] call CBA_fnc_targetEvent;
