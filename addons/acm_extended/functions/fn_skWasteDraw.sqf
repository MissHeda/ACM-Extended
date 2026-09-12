// Draw one medication component into a partially wasted 10 mL saline flush. The flush keeps its remaining saline
// as the immutable base volume; each press of Draw locks the selected medication/volume and advances the plunger
// floor, allowing another medication to be selected and drawn on top. Save is handled by ACME_fnc_skFlushSave.
disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "draw") exitWith {};

private _cap = uiNamespace getVariable ["ACME_SK_WasteCap", 10];
private _floor = uiNamespace getVariable ["ACME_SK_WasteFloorMl", 0];
private _fill = ((uiNamespace getVariable ["ACME_SK_WasteFill", ACM_circulation_SyringeDraw_DrawnAmount]) max _floor) min _cap;
private _drugMl = _fill - _floor;
private _med = ACM_circulation_SyringeDraw_Medication;
if (isNil "_med" || {_med == ""}) exitWith {["Select a medication, then draw.",2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;};
if (_drugMl <= 0.005) exitWith {["Grab the plunger and pull down to draw some drug first.",2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;};

// One click binds one physical vial. The same explicit vial-session accounting used by ordinary compounds applies
// to flushes, including the exact 0.00 mL endpoint and deliberate selection of another vial for another pull.
private _locked = uiNamespace getVariable ["ACME_SK_CompoundComponents", []];
private _lockedSame = 0;
{if ((_x param [0,""]) == _med) then {_lockedSame = _lockedSame + (_x param [1,0]);};} forEach _locked;
private _limit = ["limit",_med,_lockedSame + _drugMl,_dlg] call ACME_fnc_vialSession;
if ((_lockedSame + _drugMl) > _limit + 0.0005) exitWith {["The selected vial does not contain that much medication.",2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;};

private _components = +_locked;
_components pushBack [_med,_drugMl];
uiNamespace setVariable ["ACME_SK_CompoundComponents",_components];
uiNamespace setVariable ["ACME_SK_WasteFloorMl",_fill];
uiNamespace setVariable ["ACME_SK_WasteMoving",false];

private _medList = _dlg displayCtrl 84006;
private _medListBtn = _dlg displayCtrl 84007;
if (!isNull _medList) then {_medList ctrlEnable true;};
if (!isNull _medListBtn) then {_medListBtn ctrlEnable true;};

private _drawCount = count _components;
uiNamespace setVariable ["ACME_SK_CompoundDrawCount",_drawCount];
private _drawBtn = _dlg displayCtrl 84003;
if (!isNull _drawBtn) then {
    private _gen = (_dlg getVariable ["ACME_SK_DrawFeedbackGen",0]) + 1;
    _dlg setVariable ["ACME_SK_DrawFeedbackGen",_gen];
    _drawBtn ctrlSetText format ["Drawn! (%1)",_drawCount];
    _drawBtn ctrlSetBackgroundColor (["success",0.88] call ACME_fnc_a11yColor);
    _drawBtn ctrlCommit 0;
    [{
        params ["_oldDisplay","_expectedGen","_count"];
        private _live=findDisplay 84000;
        if (isNull _live || {!(_live isEqualTo _oldDisplay)} || {(_live getVariable ["ACME_SK_DrawFeedbackGen",0]) != _expectedGen}
            || {(uiNamespace getVariable ["ACME_SK_WasteStage",""]) != "draw"}) exitWith {};
        private _b=_live displayCtrl 84003;
        if (!isNull _b) then {_b ctrlSetText format ["Draw (%1)",_count]; _b ctrlSetBackgroundColor [0.05,0.05,0.05,0.65]; _b ctrlCommit 0;};
    },[_dlg,_gen,_drawCount],1.00] call CBA_fnc_waitAndExecute;
};
