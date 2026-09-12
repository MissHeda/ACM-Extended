// "Save" in the compound flow. take the accumulated components, generate the label, with named products such as
// ketofol recognized by their exact recipe, consume the vials, store one compound syringe in the drawn list, and
// reopen the dialog fresh. at least one component is required.
// call ACME_fnc_skCompoundSave.
disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "compound") exitWith {};

private _components = uiNamespace getVariable ["ACME_SK_CompoundComponents", []];
if (_components isEqualTo []) exitWith {
    ["Draw at least one drug before saving.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

private _cap = uiNamespace getVariable ["ACME_SK_WasteCap", 10];
private _label = [_cap, _components, 0] call ACME_fnc_skCompoundLabel;
call ACME_fnc_skPendingTagCommit;

// commit through the shared path, which the auto-save on close also uses, then report and reopen fresh.
if !(call ACME_fnc_skCompoundCommit) exitWith {};


// B73: make Save visibly acknowledge the commit before the fresh preparation dialog replaces this one.
call ACME_fnc_skRefreshDrawn;
private _size = ACM_circulation_SyringeDraw_Size;
private _patient = uiNamespace getVariable ["ACME_SK_Patient", objNull];
private _bodyPart = uiNamespace getVariable ["ACME_SK_BodyPart", ""];
private _restoreMouse = getMousePosition;
private _token = format ["%1:%2",clientOwner,diag_tickTime];
_dlg setVariable ["ACME_SK_SaveFeedbackToken",_token];
private _saveBtn = _dlg displayCtrl 84004;
private _drawBtn = _dlg displayCtrl 84003;
if (!isNull _saveBtn) then {
    _saveBtn ctrlSetText "Saved!";
    _saveBtn ctrlSetBackgroundColor (["success",0.88] call ACME_fnc_a11yColor);
    _saveBtn ctrlEnable false;
    _saveBtn ctrlCommit 0;
};
if (!isNull _drawBtn) then {_drawBtn ctrlEnable false;};
[{
    params ["_oldDisplay","_tok","_size","_patient","_bodyPart","_mouse"];
    private _live = findDisplay 84000;
    if (isNull _live || {!(_live isEqualTo _oldDisplay)} || {(_live getVariable ["ACME_SK_SaveFeedbackToken",""]) != _tok}) exitWith {};
    // Reset the visible controls before teardown so a delayed frame can never retain the green success state.
    private _save = _live displayCtrl 84004;
    private _draw = _live displayCtrl 84003;
    if (!isNull _save) then {_save ctrlSetText "Save"; _save ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];};
    if (!isNull _draw) then {_draw ctrlSetText "Draw"; _draw ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];};
    [true] call ACME_fnc_skAfterSaveOpenBody;
    [] call ACME_fnc_skWasteEnd;
    uiNamespace setVariable ["ACME_SK_RestoreMouse", _mouse];
    closeDialog 0;
    [{ _this call ACME_fnc_skOpenDraw; }, [_size, _patient, _bodyPart], 0.05] call CBA_fnc_waitAndExecute;
},[_dlg,_token,_size,_patient,_bodyPart,_restoreMouse],1.10] call CBA_fnc_waitAndExecute;
