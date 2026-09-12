/* Keep the close-focus pass after every clamp display update. */
private _acmeNVArgs = if (isNil "_this") then {[]} else {_this};
_acmeNVArgs call {
private _display = findDisplay 86200;
if (isNull _display) exitWith {};
call ACME_fnc_onClampLoad;  // idempotent; covers environments where config onload never fires

private _dragging = uiNamespace getVariable ["ACME_RollerClamp_Dragging", false];

// the cached ui state. the dialog stays alive and visually correct even when the data context cannot be resolved,
// such as a deselected bag, a closed menu or a console test.
private _dropSet = uiNamespace getVariable ["ACME_RollerClamp_DropSet", missionNamespace getVariable ["ACME_infusion_defaultDropSet", 20]];
private _position = uiNamespace getVariable ["ACME_RollerClamp_Position", 1];
private _medName = uiNamespace getVariable ["ACME_RollerClamp_MedName", ""];
private _dropsPerMinute = [_position] call ACME_fnc_clampPositionToDrops;
private _doseRemaining = -1;
private _lastVolume = -1;
private _hasEntry = false;
private _componentText = [];

private _result = call ACME_fnc_getSelectedInfusionEntryIndexes;
if !(_result isEqualTo []) then {
    _result params ["_patient", "_indexes"];
    if !(_indexes isEqualTo []) then {
        private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
        private _entryIndex = _indexes select 0;
        if (_entryIndex >= 0 && {_entryIndex < count _entries}) then {
            private _entry = _entries select _entryIndex;
            _hasEntry = true;
            _dropSet = _entry param [20, missionNamespace getVariable ["ACME_infusion_defaultDropSet", 20]];
            if (_dragging) then {
                // while grabbed, the wheel is the source of truth.
                _dropsPerMinute = [_position] call ACME_fnc_clampPositionToDrops;
            } else {
                _dropsPerMinute = _entry param [21, 60];
                _position = _entry param [22, ([_dropsPerMinute] call ACME_fnc_dropsToClampPosition)];
            };
            private _medication = _entry param [11, ""];
            _doseRemaining = _entry param [14, -1];
            _lastVolume = _entry param [10, -1];
            if (_medication isEqualType "" && {_medication != ""}) then {
                _medName = localize (format ["STR_ACM_Circulation_Medication_%1", _medication]);
                if (_medName == "") then {_medName = _medication};
            };

            private _bagId = _entry param [23, ""];
            private _same = _entries select {(_x param [23, ""]) == _bagId};
            if (_same isEqualTo []) then {_same = [_entry];};
            _componentText = _same apply {
                private _nominal = (_x param [14,0]) / ((_x param [10,0]) max 0.001) * (_dropsPerMinute / (_dropSet max 1));
                format ["%1: %2 remaining; %3/min nominal", _x select 11, [_x select 11, _x select 14] call ACME_fnc_formatDose, [_x select 11, _nominal] call ACME_fnc_formatDose]
            };
            if (count _same > 1) then {_medName = format ["Mixed infusion (%1 medications)", count _same];};
            uiNamespace setVariable ["ACME_RollerClamp_DropSet", _dropSet];
            uiNamespace setVariable ["ACME_RollerClamp_Position", _position];
            uiNamespace setVariable ["ACME_RollerClamp_MedName", _medName];
        };
    };
};

private _rateText = if (_hasEntry) then {
    [_doseRemaining, _lastVolume, _dropSet, _dropsPerMinute, _position] call ACME_fnc_formatRate
} else {
    private _mlPerMinute = if (_dropSet > 0) then {_dropsPerMinute / _dropSet} else {0};
    format ["%1 gtt/mL | %2 gtt/min | %3 mL/min | %4%5 open", round _dropSet, round _dropsPerMinute, _mlPerMinute toFixed 1, round (((_position max 0) min 1) * 100), "%"]
};

private _flash = uiNamespace getVariable ["ACME_RollerClamp_Flash", ["", -1]];
_flash params ["_flashText", "_flashUntil"];
if (_flashUntil > CBA_missionTime && {_flashText != ""}) then {
    _rateText = format ["%1  |  %2", _flashText, _rateText];
};

private _ctrlTitle = _display displayCtrl 86205;
private _ctrlRate = _display displayCtrl 86206;
private _ctrlWheel = _display displayCtrl 86202;
private _ctrlDrag = _display displayCtrl 86203;
private _ctrlBG = _display displayCtrl 86201;
private _ctrlDrop = _display displayCtrl 86207;
private _ctrlClamp = _display displayCtrl 86208;

private _percent = round (((_position max 0) min 1) * 100);
private _mlPerMinute = if (_dropSet > 0) then {_dropsPerMinute / _dropSet} else {0};
private _tooltip = format ["Roller clamp: %1%2 open | %3 gtt/mL | %4 gtt/min | %5 mL/min", _percent, "%", round _dropSet, round _dropsPerMinute, _mlPerMinute toFixed 1];

_tooltip = _tooltip + toString [10] + (_componentText joinString (toString [10]));
if (!isNull _ctrlTitle) then {
    _ctrlTitle ctrlSetTooltip _tooltip;
    _ctrlTitle ctrlSetText ([format ["Roller Clamp - %1", _medName], "Roller Clamp"] select (_medName == ""));
};
if (!isNull _ctrlRate) then {
    _ctrlRate ctrlSetText _rateText;
    _ctrlRate ctrlSetTooltip _tooltip;
};
if (!isNull _ctrlDrop) then {
    _ctrlDrop ctrlSetText (format ["Drop Set: %1", round _dropSet]);
    _ctrlDrop ctrlSetTooltip (format ["Cycle drop set (currently %1 gtt/mL)", round _dropSet]);
};
if (!isNull _ctrlClamp) then {
    _ctrlClamp ctrlSetText (["Open Clamp", "Close Clamp"] select (_dropsPerMinute > 0));
};
if (!isNull _ctrlDrag) then {_ctrlDrag ctrlSetTooltip _tooltip;};
if (!isNull _ctrlWheel) then {_ctrlWheel ctrlSetTooltip _tooltip;};
if (!isNull _ctrlBG) then {_ctrlBG ctrlSetTooltip _tooltip;};

if !(uiNamespace getVariable ["ACME_RollerClamp_LoggedUpdate", false]) then {
    uiNamespace setVariable ["ACME_RollerClamp_LoggedUpdate", true];
};

// the per-frame mover owns the wheel while it is grabbed.
if (!_dragging) then {
    [_position] call ACME_fnc_placeClampWheel;
};

};
[findDisplay 86200, [], "ACME_Clamp_Shade"] call ACME_fnc_darknessShade;
[findDisplay 86200] call ACME_fnc_minigameVisionTick;
