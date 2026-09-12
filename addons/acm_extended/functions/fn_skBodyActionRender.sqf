/* B76: one contextual button directly above Draw Syringe on Body Map.
   Default: blinking red two-press Discard Syringe. After a site is chosen: explicit Push/Inject confirmation for
   the currently selected carousel syringe. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d) exitWith {};
private _back = _d displayCtrl 84819;
private _btn = _d displayCtrl 84820;
if (isNull _back || {isNull _btn}) exitWith {};
private _body = (uiNamespace getVariable ["ACME_SK_View","syringe"]) == "body";
private _editMode = uiNamespace getVariable ["ACME_SK_TagEditMode",false];
private _busy = uiNamespace getVariable ["ACME_SK_InjectionBusy",false];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store,false] call ACME_fnc_skSelectedIndex;
private _usable = _body && {!_editMode} && {_idx >= 0} && {_idx < count _store} && {(uiNamespace getVariable ["ACME_SK_SelFlush",""]) == ""};
if (!_usable) exitWith {_back ctrlShow false; _btn ctrlShow false;};

private _view = _d displayCtrl 84150;
private _vr = +(ctrlPosition _view);
private _gap = safeZoneH * 0.006;
private _r = [_vr select 0, (_vr select 1) - (_vr select 3) - _gap, _vr select 2, _vr select 3];
_back ctrlSetPosition _r; _btn ctrlSetPosition _r;
_back ctrlCommit 0; _btn ctrlCommit 0;

private _entry = _store select _idx;
private _id = _entry param [11,"",[""]];
private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
if (_pending isEqualType [] && {count _pending >= 3}) then {
    _pending params ["_part","_site","_route"];
    private _total = ((_entry param [2,0,[0]]) + (_entry param [4,0,[0]])) max 0;
    private _ml = _total;
    if ((_entry param [6,"",[""]]) == "epiMixB12") then {
        private _choice = uiNamespace getVariable ["ACME_SK_EpiDoseChoice",0];
        _ml = ([1,2,_total] select (((_choice max 0) min 2))) min _total;
    };
    private _mlText = if (abs (_ml - round _ml) < 0.0005) then {str (round _ml)} else {if (abs (_ml*10 - round (_ml*10)) < 0.0005) then {_ml toFixed 1} else {_ml toFixed 2}};
    private _where = [_part,"abbr"] call ACME_fnc_bodyPartName;
    private _verb = "Inject";
    if (_route != "im") then {
        _verb = "Push";
        private _siteName = "IO";
        if (_site >= 0) then {
            private _catalog = [_part,_site] call ACME_fnc_ivVeinCatalog;
            _siteName = if (_catalog isEqualType createHashMap && {count _catalog > 0}) then {
                _catalog getOrDefault ["short",[_part,_site,false] call ACME_fnc_skSiteName]
            } else {
                [_part,_site,false] call ACME_fnc_skSiteName
            };
        };
        _where = if (_siteName == "") then {_where} else {format ["%1 %2",_where,_siteName]};
    };
    _btn ctrlSetText format ["%1 %2 mL in %3",_verb,_mlText,_where];
    _btn ctrlSetTooltip "Confirm administration of the currently selected syringe at the selected site";
    _btn ctrlEnable (!_busy && {_total > 0});
    _back ctrlSetBackgroundColor (["success",0.82] call ACME_fnc_a11yColor);
} else {
    private _armed = uiNamespace getVariable ["ACME_SK_DiscardArmedId",""];
    if (_armed != _id) then {uiNamespace setVariable ["ACME_SK_DiscardArmedId",""]; _armed = "";};
    _btn ctrlSetText (if (_armed == _id) then {"Confirm discard?"} else {"Discard Syringe"});
    _btn ctrlSetTooltip "Discard the currently selected syringe. Requires two presses.";
    _btn ctrlEnable (!_busy);
    private _a = 0.48 + 0.42 * (0.5 + 0.5 * sin (diag_tickTime * 300));
    _back ctrlSetBackgroundColor (["danger",_a] call ACME_fnc_a11yColor);
};
_back ctrlShow true;
_btn ctrlShow true;
_btn ctrlCommit 0;
