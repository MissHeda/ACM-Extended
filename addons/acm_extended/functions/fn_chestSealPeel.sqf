// A removal changes only this seal. Closing the panel never publishes the full chest.
params ["_idx"];
private _holes = uiNamespace getVariable ["ACME_CS_Holes", []];
if (_idx < 0 || {_idx >= count _holes}) exitWith {};
private _hole = _holes select _idx;
if !(_hole select 4) exitWith {};
if !(["peel", [_hole] call ACME_fnc_chestSealKey] call ACME_fnc_chestSealRequest) exitWith {};
(_holes select _idx) set [4, false];
uiNamespace setVariable ["ACME_CS_Holes", _holes];
[] call ACME_fnc_chestSealRender;
