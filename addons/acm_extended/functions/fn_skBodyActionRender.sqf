/* B76: one contextual button directly above Draw Syringe on Body Map.
   Default: blinking red two-press Discard Syringe. After a site is chosen: explicit Push/Inject confirmation for
   the currently selected carousel syringe. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d) exitWith {};
private _back = _d displayCtrl 84819;
private _btn = _d displayCtrl 84820;
if (isNull _back || {isNull _btn}) exitWith {};

// Push-duration controls are available for every vascular syringe administration. The grey number is guidance
// only. If the provider does not enter a number, the actual push defaults to 3 seconds in both normal and Hardcore
// medication modes.
private _hcMed = missionNamespace getVariable ["ACME_hcEff_medications",false];
private _durLabel = _d displayCtrl 84830;
private _durEdit = _d displayCtrl 84831;
if (isNull _durLabel) then {
        _durLabel = _d ctrlCreate ["RscText",84830];
        _durLabel ctrlSetText "Seconds to Push over:";
        _durLabel ctrlSetTextColor [0.94,0.91,0.82,1];
        _durLabel ctrlSetBackgroundColor [0.043,0.082,0.188,0.90];
        _durLabel ctrlEnable false;
    };
    if (isNull _durEdit) then {
        _durEdit = _d ctrlCreate ["RscEdit",84831];
        _durEdit ctrlSetText "";
        _durEdit ctrlSetTextColor [1,1,1,1];
        _durEdit ctrlSetBackgroundColor [0.02,0.03,0.06,0.94];
        _durEdit ctrlSetTooltip "Optional: type whole seconds to push over (1-300). Leave it blank for 3 seconds. Grey text is the recommended value.";
        _durEdit setVariable ["ACME_SK_GhostActive",false];
        _durEdit setVariable ["ACME_SK_GhostText",""];
        _durEdit ctrlAddEventHandler ["MouseButtonDown", {
            params ["_ctrl"];
            if (_ctrl getVariable ["ACME_SK_GhostActive",false]) then {
                _ctrl ctrlSetText "";
                _ctrl ctrlSetTextColor [1,1,1,1];
                _ctrl setVariable ["ACME_SK_GhostActive",false];
            };
        }];
        // Clear the grey recommendation when the edit actually receives focus, not inside KeyDown. Changing
        // ctrlText during KeyDown races Arma's own RscEdit key processing and can swallow every attempted digit.
        _durEdit ctrlAddEventHandler ["SetFocus", {
            params ["_ctrl"];
            if (_ctrl getVariable ["ACME_SK_GhostActive",false]) then {
                _ctrl ctrlSetText "";
                _ctrl ctrlSetTextColor [1,1,1,1];
                _ctrl setVariable ["ACME_SK_GhostActive",false];
            };
        }];
        _durEdit ctrlAddEventHandler ["KeyUp", {
            params ["_ctrl"];
            if !(_ctrl getVariable ["ACME_SK_GhostActive",false]) then {
                private _raw = ctrlText _ctrl;
                private _clean = toString ((toArray _raw) select {_x >= 48 && {_x <= 57}});
                if (_clean != _raw) then {_ctrl ctrlSetText _clean;};
            };
        }];
        _durEdit ctrlAddEventHandler ["KillFocus", {
            params ["_ctrl"];
            if ((ctrlText _ctrl) == "") then {
                private _g = _ctrl getVariable ["ACME_SK_GhostText",""];
                if (_g != "") then {
                    _ctrl ctrlSetText _g;
                    _ctrl ctrlSetTextColor [0.56,0.58,0.62,0.82];
                    _ctrl setVariable ["ACME_SK_GhostActive",true];
                };
            };
        }];
    };
private _durFocusCtrl = focusedCtrl _d;
private _durFocused = !isNull _durFocusCtrl && {_durFocusCtrl isEqualTo _durEdit};

private _body = (uiNamespace getVariable ["ACME_SK_View","syringe"]) == "body";
private _editMode = uiNamespace getVariable ["ACME_SK_TagEditMode",false];
private _busy = uiNamespace getVariable ["ACME_SK_InjectionBusy",false];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store,false] call ACME_fnc_skSelectedIndex;
private _usable = _body && {!_editMode} && {_idx >= 0} && {_idx < count _store} && {(uiNamespace getVariable ["ACME_SK_SelFlush",""]) == ""};
if (!_usable) exitWith {
    _back ctrlShow false;
    _btn ctrlShow false;
    _durLabel ctrlShow false; _durEdit ctrlShow false;
};

private _viewL = _d displayCtrl 84150;
private _viewR = _d displayCtrl 84152;
private _vl = +(ctrlPosition _viewL);
private _vr = +(ctrlPosition _viewR);
private _gap = safeZoneH * 0.006;
private _actionX = _vl select 0;
private _actionW = ((_vr select 0) + (_vr select 2)) - _actionX;
private _r = [_actionX, (_vl select 1) - (_vl select 3) - _gap, _actionW, _vl select 3];
_back ctrlSetPosition _r; _btn ctrlSetPosition _r;
_back ctrlCommit 0; _btn ctrlCommit 0;

// Keep the duration row physically attached to the green Push button. This used to be ordinary executable
// layout code; wrapping it in a bare {...} code literal stopped it from running and left the controls at their
// default coordinates. Use the live Push rectangle every render so page-navigation/layout changes cannot offset it.
private _pushRect = +(ctrlPosition _btn);
private _durGap = 2 * pixelW;
private _durH = (_pushRect select 3) * 0.82;
private _durY = (_pushRect select 1) - _durH - (_gap * 0.65);
private _editW = (_pushRect select 2) * 0.23;
private _labelW = (_pushRect select 2) - _editW - _durGap;
_durLabel ctrlSetPosition [_pushRect select 0, _durY, _labelW, _durH];
_durLabel ctrlSetFontHeight (_durH * 0.63);
_durLabel ctrlCommit 0;
// RscEdit loses keyboard/caret ownership when layout/enable state is repeatedly rewritten while it has focus.
// The UI tick renders this function continuously, so leave the edit control physically untouched during typing.
if (!_durFocused) then {
    _durEdit ctrlSetPosition [(_pushRect select 0) + _labelW + _durGap, _durY, _editW, _durH];
    _durEdit ctrlSetFontHeight (_durH * 0.63);
    _durEdit ctrlCommit 0;
};

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
    if (_hcMed) then {
        _durLabel ctrlShow true;
        _durEdit ctrlShow true;
        _durEdit ctrlEnable false;
        _durEdit setVariable ["ACME_SK_GhostActive",false];
        _durEdit ctrlSetTextColor [1,1,1,1];
        _durEdit ctrlSetText str (round (_hcJob getOrDefault ["duration",3]));
    };
    _back ctrlShow true;
    _btn ctrlShow true;
    _btn ctrlCommit 0;
};
if (_pending isEqualType [] && {count _pending >= 3}) then {
    _pending params ["_part","_site","_route"];
    if (_route != "im") then {
        private _defaultFor = _d getVariable ["ACME_HCMedPushDefaultFor",""];
        if (!_durFocused && {_defaultFor != _id}) then {
            private _suggested = str (round ([_entry] call ACME_fnc_medicationSuggestedPushSec));
            _durEdit setVariable ["ACME_SK_GhostText",_suggested];
            _durEdit setVariable ["ACME_SK_GhostActive",true];
            _durEdit ctrlSetText _suggested;
            _durEdit ctrlSetTextColor [0.56,0.58,0.62,0.82];
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
    private _validPushTime = true;
    if (_route != "im") then {
        private _ghost = _durEdit getVariable ["ACME_SK_GhostActive",false];
        private _rawDur = if (_ghost) then {""} else {ctrlText _durEdit};
        private _hasTypedDuration = !_ghost && {_rawDur != ""};
        private _numDur = if (_hasTypedDuration) then {parseNumber _rawDur} else {3};
        // Blank or grey-placeholder means "use the 3 s fallback". Only an explicitly typed out-of-range value blocks.
        _validPushTime = !_hasTypedDuration || {_numDur >= 1 && {_numDur <= 300}};
    };
    _btn ctrlEnable (!_busy && {_total > 0} && {_validPushTime});
    _btn ctrlSetTooltip (if (_validPushTime) then {"Confirm administration. If no push time is entered, 3 seconds is used."} else {"Push duration must be 1-300 seconds. Grey text is only the recommendation."});
    _back ctrlSetBackgroundColor (["success",0.82] call ACME_fnc_a11yColor);
    private _showDuration = _route != "im";
    _durLabel ctrlShow _showDuration;
    if (!_durFocused) then {
        _durEdit ctrlShow _showDuration;
        _durEdit ctrlEnable (_showDuration && {!_busy});
    };
} else {
    _durLabel ctrlShow false; _durEdit ctrlShow false;
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
