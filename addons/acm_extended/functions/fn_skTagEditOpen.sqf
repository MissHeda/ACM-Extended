/* B69: enter the dedicated stored-syringe tag editor from Body Map.
   Existing tags expose/focus their first text line. Untagged syringes show only Select Syringe Tag until a color is chosen. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body"}) exitWith {false};
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store] call ACME_fnc_skSelectedIndex;
if (_idx < 0) exitWith {false};

private _list = _d displayCtrl 84471;
if (!isNull _list) then {_list lbSetCurSel -1; _list ctrlShow false;};
uiNamespace setVariable ["ACME_SK_TagEditMode", true];
uiNamespace setVariable ["ACME_SK_CarouselExpanded", true];
uiNamespace setVariable ["ACME_SK_CarouselHover", false];
uiNamespace setVariable ["ACME_SK_CarouselZoneHover", true];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt", 0];
[0.12] call ACME_fnc_skDynamicLayout;
[0.12] call ACME_fnc_skCarouselRender;
call ACME_fnc_skBuildHotspots;

[{
    disableSerialization;
    private _d = findDisplay 84000;
    if (isNull _d || {!(uiNamespace getVariable ["ACME_SK_TagEditMode",false])}) exitWith {};
    private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
    private _idx = [_store,false] call ACME_fnc_skSelectedIndex;
    private _color = if (_idx >= 0) then {(_store select _idx) param [7,"none",[""]]} else {"none"};
    private _focusCtrl = _d displayCtrl (if (_color in ["","none"]) then {84470} else {84460});
    if (!isNull _focusCtrl) then {ctrlSetFocus _focusCtrl;};
}, [], 0.14] call CBA_fnc_waitAndExecute;
true
