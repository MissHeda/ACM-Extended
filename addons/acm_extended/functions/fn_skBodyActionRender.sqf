/* B76: one contextual button directly above Draw Syringe on Body Map.
   Default: blinking red two-press Discard Syringe. After a site is chosen: explicit Push/Inject confirmation for
   the currently selected carousel syringe. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d) exitWith {};
private _back = _d displayCtrl 84819;
private _btn = _d displayCtrl 84820;
if (isNull _back || {isNull _btn}) exitWith {};

// B115: optional manual IV/IO push duration. These controls are runtime-owned so the existing Narc Box config and
// all preparation-page layouts remain untouched. Blank means the original 3-second push.
private _durLabel = _d displayCtrl 84830;
if (isNull _durLabel) then {
    _durLabel = _d ctrlCreate ["RscText", 84830];
    _durLabel ctrlSetText "Seconds to Push over:";
    _durLabel ctrlSetTextColor [0.94,0.91,0.82,1];
    _durLabel ctrlSetBackgroundColor [0.043,0.082,0.188,0.90];
    _durLabel ctrlEnable false;
};
private _durEdit = _d displayCtrl 84831;
if (isNull _durEdit) then {
    _durEdit = _d ctrlCreate ["RscEdit", 84831];
    _durEdit ctrlSetText "";
    _durEdit ctrlSetTextColor [1,1,1,1];
    _durEdit ctrlSetBackgroundColor [0.02,0.03,0.06,0.94];
    _durEdit ctrlSetTooltip "Whole seconds to push the medication over (1-300). Leave blank for 3 seconds.";
    _durEdit ctrlAddEventHandler ["KeyUp", {
        params ["_ctrl"];
        private _raw = ctrlText _ctrl;
        private _clean = toString ((toArray _raw) select {_x >= 48 && {_x <= 57}});
        if (_clean != _raw) then {_ctrl ctrlSetText _clean;};
    }];
};
private _body = (uiNamespace getVariable ["ACME_SK_View","syringe"]) == "body";
private _editMode = uiNamespace getVariable ["ACME_SK_TagEditMode",false];
private _busy = uiNamespace getVariable ["ACME_SK_InjectionBusy",false];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store,false] call ACME_fnc_skSelectedIndex;
private _usable = _body && {!_editMode} && {_idx >= 0} && {_idx < count _store} && {(uiNamespace getVariable ["ACME_SK_SelFlush",""]) == ""};
if (!_usable) exitWith {
    _back ctrlShow false;
    _btn ctrlShow false;
    _durLabel ctrlShow false;
    _durEdit ctrlShow false;
};

private _view = _d displayCtrl 84150;
private _vr = +(ctrlPosition _view);
private _gap = safeZoneH * 0.006;
private _r = [_vr select 0, (_vr select 1) - (_vr select 3) - _gap, _vr select 2, _vr select 3];
_back ctrlSetPosition _r; _btn ctrlSetPosition _r;
_back ctrlCommit 0; _btn ctrlCommit 0;

private _durGap = 2 * pixelW;
private _durH = (_r select 3) * 0.82;
private _durY = (_r select 1) - _durH - (_gap * 0.65);
private _editW = (_r select 2) * 0.23;
private _labelW = (_r select 2) - _editW - _durGap;
_durLabel ctrlSetPosition [_r select 0, _durY, _labelW, _durH];
_durEdit ctrlSetPosition [(_r select 0) + _labelW + _durGap, _durY, _editW, _durH];
_durLabel ctrlSetFontHeight (_durH * 0.63);
_durEdit ctrlSetFontHeight (_durH * 0.63);
_durLabel ctrlCommit 0;
_durEdit ctrlCommit 0;

private _entry = _store select _idx;
private _id = _entry param [11,"",[""]];
private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
// B121: an active Hardcore push owns this exact stable syringe. The normal green confirmation becomes a red
// Stop Push control. It remains clickable even though carousel/site controls are deliberately locked.
private _hcJob = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
private _hcOwns = _hcJob isEqualType createHashMap && {count _hcJob > 0} && {(_hcJob getOrDefault ["stableId",""]) == _id};
if (_hcOwns) exitWith {
    private _flowing = _hcJob getOrDefault ["flowing",false];
    _btn ctrlSetText (if (_flowing) then {"Stop Push"} else {"Stopping..."});
    _btn ctrlSetTooltip (if (_flowing) then {"Stop the active medication push and preserve the exact remaining syringe volume"} else {"Settling the last delivered medication volume"});
    _btn ctrlEnable _flowing;
    _back ctrlSetBackgroundColor (["danger",0.90] call ACME_fnc_a11yColor);
    _durLabel ctrlShow true;
    _durEdit ctrlShow true;
    _durEdit ctrlEnable false;
    _durEdit ctrlSetText str (round (_hcJob getOrDefault ["duration",3]));
    _back ctrlShow true;
    _btn ctrlShow true;
    _btn ctrlCommit 0;
};
if (_pending isEqualType [] && {count _pending >= 3}) then {
    _pending params ["_part","_site","_route"];
    if ((missionNamespace getVariable ["ACME_hcEff_medications",false]) && {_route != "im"}) then {
        private _defaultFor = _d getVariable ["ACME_HCMedPushDefaultFor",""];
        if (_defaultFor != _id) then {
            _durEdit ctrlSetText str ([_entry] call ACME_fnc_medicationSuggestedPushSec);
            _d setVariable ["ACME_HCMedPushDefaultFor",_id];
        };
    };
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
    private _showDuration = _route != "im";
    _durLabel ctrlShow _showDuration;
    _durEdit ctrlShow _showDuration;
    _durEdit ctrlEnable (_showDuration && {!_busy});
} else {
    _durLabel ctrlShow false;
    _durEdit ctrlShow false;
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
