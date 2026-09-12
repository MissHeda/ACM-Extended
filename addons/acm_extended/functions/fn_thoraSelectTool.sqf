// toggle the held tool from the right-side tray. clicking the held tool again puts it down, back to palpation.
// the workflow is manual: nothing auto-advances, and the medic picks each tool in turn. it highlights the active
// slot.
// call it as [_tool] call ACME_fnc_thoraSelectTool, where _tool is "chlorhexidine", "scalpel", "kelly", "finger" or
// "tube".
params ["_tool"];
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};

private _held = uiNamespace getVariable ["ACME_Thora_Held", ""];
private _medic = uiNamespace getVariable ["ACME_Thora_Medic", objNull];
([_medic] call ACME_fnc_thoraClosureMode) params ["_closure", "_count", "_canTube"];
// The shared tray slot resolves to a real held seal or tube at pickup.
// Pressing that slot again always puts down the current closure.
if (_tool == "tube") then {
    _tool = if (_held in ["seal", "tube"]) then {_held} else {_closure};
};
if (_held isEqualTo _tool) then { _tool = ""; };
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
if (_tool in ["scalpel", "kelly", "finger"] && {
    !([_medic, "thoracostomy"] call ACME_fnc_procedureAllowed)
    || {([_medic, _patient] call ACME_fnc_thoraKitItem) == ""}
}) exitWith {};
if (_tool == "tube" && {!_canTube}) exitWith {};
if (_tool == "seal" && {!([_medic, "thoracostomySeal", true] call ACME_fnc_procedureAllowed)}) exitWith {};
if (_tool == "seal" && {(isNull _medic) || {([_medic, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem) < 1}}) exitWith {};
uiNamespace setVariable ["ACME_Thora_Held", _tool];
uiNamespace setVariable ["ACME_Thora_TubeSnap", false];
uiNamespace setVariable ["ACME_Thora_SealMode", if (_tool in ["seal", "tube"]) then {_tool == "seal"} else {_closure == "seal"}];
[] call ACME_fnc_thoraUpdateTrayIcons;

// any tool change cancels an in-progress cut and palpation.
uiNamespace setVariable ["ACME_Thora_Palpating", false];
uiNamespace setVariable ["ACME_Thora_Cutting", false];
uiNamespace setVariable ["ACME_Thora_Prepping", false];
uiNamespace setVariable ["ACME_Thora_KellyArmed", false];

// highlight the active slot, with a brighter background, and dim the rest.
{
    private _bg = _x;
    private _slotTool = _bg getVariable ["thoraTool", ""];
    private _ic = _bg getVariable ["thoraIcon", controlNull];
    private _isSel = (_slotTool isEqualTo _tool) || {_slotTool == "tube" && {_tool == "seal"}};
    _bg ctrlSetBackgroundColor ([[0, 0, 0, 0.85], [0.20, 0.28, 0.18, 0.9]] select _isSel);
    // the picked-up tool leaves an all-black silhouette in its slot, so it looks like it was lifted out of its spot.
    if (!isNull _ic) then {
        if (_isSel && {_tool != ""}) then {
            _ic ctrlSetTextColor [0, 0, 0, 1];
        } else {
            _ic ctrlSetTextColor [1, 1, 1, 0.85];
        };
    };
} forEach (uiNamespace getVariable ["ACME_Thora_SlotBGs", []]);
