// Keep the placement gesture immediate; reserve the item locally and commit on the server.
params ["_idx"];
private _holes = uiNamespace getVariable ["ACME_CS_Holes", []];
if (_idx < 0 || {_idx >= count _holes}) exitWith {};
private _hole = _holes select _idx;
if (_hole select 4) exitWith {};
private _key = [_hole] call ACME_fnc_chestSealKey;
if !(["seal", _key, "ACM_ChestSeal"] call ACME_fnc_chestSealRequest) exitWith {};
(_holes select _idx) set [4, true];
uiNamespace setVariable ["ACME_CS_Holes", _holes];
uiNamespace setVariable ["ACME_CS_Held", false];
private _medic = uiNamespace getVariable ["ACME_CS_Medic", objNull];
uiNamespace setVariable ["ACME_CS_SealsLeft", [_medic, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem];
// B52: one exact placement gesture. A second seal cannot restart it while the first gesture is still owned.
if (!isNull _medic && {local _medic}) then {[_medic,"chestSeal",2.0] call ACME_fnc_treatmentGesture;};

[] call ACME_fnc_chestSealRefreshSlot;
[] call ACME_fnc_chestSealRender;
[] call ACME_fnc_chestSealPrompt;
