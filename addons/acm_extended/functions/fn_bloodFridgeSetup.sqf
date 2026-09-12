// server-side: turn a freshly-created closed fridge into a working unit. it creates the co-located open-model
// twin, hidden until in use, seeds the stock and restock defaults, and registers the fridge for the server tick,
// which drives the viewer-based open and close and the daily restock. it is idempotent through the ACME_bf_setup
// guard.
// _this is [_closed, _stock, _restock], where _stock is [[bloodclass, count], ...].
params ["_closed", ["_stock", []], ["_restock", true]];
if (!isServer || isNull _closed) exitWith {};
if (_closed getVariable ["ACME_bf_setup", false]) exitWith {};
_closed setVariable ["ACME_bf_setup", true];

private _pos = getPosATL _closed;
private _dir = getDir _closed;

// the co-located open-door twin. it starts hidden, and the tick shows it while anyone is using the fridge.
private _open = createVehicle ["ACME_BloodFridge_Open", _pos, [], 0, "CAN_COLLIDE"];
_open setDir _dir;
_open setPosATL _pos;
_open hideObjectGlobal true;

// the anchor, the closed model, holds all the state. the object refs and the stock are broadcast so clients can
// build the take menu and resolve the anchor from whichever model they interact with.
_closed setVariable ["ACME_bloodFridge", true, true];
_closed setVariable ["ACME_bf_anchor", _closed, true];
_closed setVariable ["ACME_bf_openObj", _open, true];
_closed setVariable ["ACME_bf_stock", _stock, true];
_closed setVariable ["ACME_bf_default", +_stock, true];
_closed setVariable ["ACME_bf_restock", _restock, true];
// this is kept so the contents screen can say when it next refills, rather than only whether it does.
_closed setVariable ["ACME_bf_regenMins", (_closed getVariable ["ACME_bf_regenMins", (missionNamespace getVariable ["ACME_bf_regenMinsDefault", 1440])]), true];
_closed setVariable ["ACME_bf_open", false, true];
_closed setVariable ["ACME_bf_viewers", createHashMap];  // owner-local: netid -> last ping time

_open setVariable ["ACME_bloodFridge", true, true];
_open setVariable ["ACME_bf_anchor", _closed, true];

private _list = missionNamespace getVariable ["ACME_bloodFridges", []];
_list pushBackUnique _closed;
missionNamespace setVariable ["ACME_bloodFridges", _list];
