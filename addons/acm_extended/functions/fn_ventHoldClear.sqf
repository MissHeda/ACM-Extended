// tear down the power-off hold ui. it is called on release, on fire, on a screen change and on a panel close.
// it must be safe to call when nothing is up, because it is called from all of those places and several of them
// overlap. cheap and idempotent beats clever and conditional.
if (!hasInterface) exitWith {};
private _c = uiNamespace getVariable ["ACME_vent_holdUI", []];
if (_c isEqualTo []) exitWith {};
{ if (!isNull _x) then { ctrlDelete _x; }; } forEach _c;
uiNamespace setVariable ["ACME_vent_holdUI", []];
