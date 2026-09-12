/* Resolve the closure tool from the captured treating provider.
   Preserve the existing Doctor requirement for chest tubes from fn_thoraInit.
   The slot is only a selector; the held tool keeps its identity until put down. */
params [["_medic", objNull, [objNull]]];
if (isNull _medic) exitWith {["seal", 0, false]};
private _tubeCount = [_medic, "ACM_ChestTubeKit"] call ace_common_fnc_getCountOfItem;
private _canTube = (_tubeCount > 0) && {[_medic, "chestTube"] call ACME_fnc_procedureAllowed};
if (_canTube) exitWith {["tube", _tubeCount, true]};
private _sealCount = if ([_medic, "thoracostomySeal", true] call ACME_fnc_procedureAllowed) then {
    [_medic, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem
} else {0};
["seal", _sealCount, false]
