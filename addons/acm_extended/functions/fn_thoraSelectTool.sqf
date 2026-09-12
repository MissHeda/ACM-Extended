// Toggle a held tool from the thoracostomy tray. The second argument marks a real tray click on one of the new
// dedicated closure slots. One-argument legacy calls are retained so the placement code can still put down the
// currently held closure without needing to know whether it was a tube or a seal.
params ["_tool", ["_explicitClosure", false]];
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};

private _held = uiNamespace getVariable ["ACME_Thora_Held", ""];
private _medic = uiNamespace getVariable ["ACME_Thora_Medic", objNull];
([_medic] call ACME_fnc_thoraClosureMode) params ["_closure", "_count", "_canTube"];

// B93: tray buttons pass _explicitClosure=true and keep their own identities. The legacy internal ["tube"] call
// after placement deliberately resolves to whichever closure is currently held, which makes it a put-down action
// for both tube and seal without touching the large mouse handler.
if (_tool == "tube" && {!_explicitClosure}) then {
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
uiNamespace setVariable ["ACME_Thora_SealMode", _tool == "seal"];

// Any tool change cancels an in-progress cut and palpation.
uiNamespace setVariable ["ACME_Thora_Palpating", false];
uiNamespace setVariable ["ACME_Thora_Cutting", false];
uiNamespace setVariable ["ACME_Thora_Prepping", false];
uiNamespace setVariable ["ACME_Thora_KellyArmed", false];

// Highlight only the actual selected slot once the dedicated closure layout exists. Keep the old shared-slot alias
// solely for a hot-reloaded dialog that predates this build.
private _separateClosures = uiNamespace getVariable ["ACME_Thora_SeparateClosureSlots", false];
{
    private _bg = _x;
    private _slotTool = _bg getVariable ["thoraTool", ""];
    private _ic = _bg getVariable ["thoraIcon", controlNull];
    private _isSel = (_slotTool isEqualTo _tool)
        || {!_separateClosures && {_slotTool == "tube" && {_tool == "seal"}}};
    _bg ctrlSetBackgroundColor ([[0, 0, 0, 0.85], [0.20, 0.28, 0.18, 0.9]] select _isSel);
    if (!isNull _ic) then {
        if (_isSel && {_tool != ""}) then {
            _ic ctrlSetTextColor [0, 0, 0, 1];
        } else {
            private _locked = _bg getVariable ["thoraLocked", false];
            _ic ctrlSetTextColor (if (_locked) then {[0.4,0.4,0.4,0.5]} else {[1,1,1,0.85]});
        };
    };
} forEach (uiNamespace getVariable ["ACME_Thora_SlotBGs", []]);

[] call ACME_fnc_thoraUpdateTrayIcons;
