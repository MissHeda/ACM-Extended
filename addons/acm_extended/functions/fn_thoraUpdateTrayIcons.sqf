// Keep the thoracostomy tray side-correct and expose chest tube + chest seal as two real closure choices.
// The original tray had one last slot that silently changed identity between a tube and a seal. That meant a
// Doctor carrying a chest-tube kit could never select the seal even though Doctors also satisfy the Medic-tier
// seal permission. We split that existing last row into two independent half-width slots the first time this
// function runs, so no dialog/config rebuild is needed and both choices fit in the same tray footprint.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
private _slots = uiNamespace getVariable ["ACME_Thora_SlotBGs", []];

if (!isNull _display && {(_slots findIf {(_x getVariable ["thoraTool", ""]) == "seal"}) < 0}) then {
    private _tubeIndex = _slots findIf {(_x getVariable ["thoraTool", ""]) == "tube"};
    if (_tubeIndex >= 0) then {
        private _tubeBG = _slots select _tubeIndex;
        private _p = ctrlPosition _tubeBG;
        _p params ["_x", "_y", "_oldW", "_h"];
        private _gap = (_oldW * 0.06) max 0.0005;
        private _halfW = ((_oldW - _gap) / 2) max 0.001;
        private _sealX = _x + _halfW + _gap;
        private _ixPad = _halfW * 0.13;
        private _iyPad = _h * 0.14;
        private _iconW = _halfW - (2 * _ixPad);
        private _iconH = _h - (2 * _iyPad);

        // Left half remains the chest-tube slot. Rewire its click as an explicit tube choice instead of the legacy
        // dynamic closure selector. The internal one-argument call is still supported by thoraSelectTool so old
        // cleanup code can put down whichever closure is currently held.
        _tubeBG ctrlSetPosition [_x, _y, _halfW, _h];
        _tubeBG ctrlCommit 0;
        private _tubeIcon = _tubeBG getVariable ["thoraIcon", controlNull];
        if (!isNull _tubeIcon) then {
            _tubeIcon ctrlSetPosition [_x + _ixPad, _y + _iyPad, _iconW, _iconH];
            _tubeIcon ctrlCommit 0;
        };
        private _tubeBtn = _tubeBG getVariable ["thoraBtn", controlNull];
        if (!isNull _tubeBtn) then {
            _tubeBtn ctrlSetPosition [_x, _y, _halfW, _h];
            _tubeBtn setVariable ["thoraIconRect", [_x + _ixPad, _y + _iyPad, _iconW, _iconH]];
            _tubeBtn ctrlRemoveAllEventHandlers "ButtonClick";
            _tubeBtn ctrlAddEventHandler ["ButtonClick", {["tube", true] call ACME_fnc_thoraSelectTool;}];
            _tubeBtn ctrlSetTooltip "Place a chest tube";
            _tubeBtn ctrlCommit 0;
        };
        private _tubeCount = _tubeBG getVariable ["thoraCount", controlNull];
        if (!isNull _tubeCount) then {
            _tubeCount ctrlSetPosition [_x, _y + (_h * 0.60), _halfW - (_h * 0.03), _h * 0.36];
            _tubeCount ctrlCommit 0;
        };

        // Right half is always a chest seal. Permission is Medic-tier and therefore includes Doctors as well.
        private _medic = uiNamespace getVariable ["ACME_Thora_Medic", objNull];
        private _sealAllowed = !isNull _medic && {[_medic, "thoracostomySeal", true] call ACME_fnc_procedureAllowed};
        private _sealCountN = if (_sealAllowed) then {[_medic, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem} else {0};
        private _sealAvailable = _sealAllowed && {_sealCountN > 0};

        private _sealBG = _display ctrlCreate ["RscText", -1];
        _sealBG ctrlSetPosition [_sealX, _y, _halfW, _h];
        _sealBG ctrlSetBackgroundColor [0, 0, 0, 0.85];
        _sealBG setVariable ["thoraTool", "seal"];
        _sealBG setVariable ["thoraLocked", !_sealAvailable];
        _sealBG ctrlCommit 0;

        private _sealIcon = _display ctrlCreate ["RscPicture", -1];
        _sealIcon ctrlSetPosition [_sealX + _ixPad, _y + _iyPad, _iconW, _iconH];
        _sealIcon ctrlSetText "\x\acm\addons\breathing\ui\chestseal_ca.paa";
        _sealIcon ctrlSetTextColor (if (_sealAvailable) then {[1,1,1,0.85]} else {[0.4,0.4,0.4,0.5]});
        _sealIcon ctrlCommit 0;
        _sealBG setVariable ["thoraIcon", _sealIcon];

        private _sealCount = _display ctrlCreate ["RscStructuredText", -1];
        _sealCount ctrlSetPosition [_sealX, _y + (_h * 0.60), _halfW - (_h * 0.03), _h * 0.36];
        _sealCount ctrlSetStructuredText parseText format ["<t align='right' size='0.75' color='%1'>x%2</t>", if (_sealCountN > 0) then {"#ffffff"} else {"#ff6666"}, _sealCountN];
        _sealCount ctrlCommit 0;
        _sealBG setVariable ["thoraCount", _sealCount];

        private _sealBtn = _display ctrlCreate ["ACME_Thora_SlotBtn", -1];
        _sealBtn ctrlSetPosition [_sealX, _y, _halfW, _h];
        _sealBtn ctrlSetText "";
        _sealBtn ctrlSetTooltip "Place a chest seal";
        _sealBtn setVariable ["thoraTool", "seal"];
        _sealBtn setVariable ["thoraLocked", !_sealAvailable];
        _sealBtn setVariable ["thoraIcon", _sealIcon];
        _sealBtn setVariable ["thoraBG", _sealBG];
        _sealBtn setVariable ["thoraBtnSelf", _sealBtn];
        _sealBtn setVariable ["thoraIconRect", [_sealX + _ixPad, _y + _iyPad, _iconW, _iconH]];
        _sealBtn ctrlSetBackgroundColor [0,0,0,0];
        _sealBtn ctrlEnable _sealAvailable;
        _sealBtn ctrlAddEventHandler ["ButtonClick", {["seal", true] call ACME_fnc_thoraSelectTool;}];
        _sealBtn ctrlAddEventHandler ["MouseEnter", { [(_this select 0), true] call ACME_fnc_thoraSlotHover; }];
        _sealBtn ctrlAddEventHandler ["MouseExit", { [(_this select 0), false] call ACME_fnc_thoraSlotHover; }];
        _sealBtn ctrlCommit 0;
        _sealBG setVariable ["thoraBtn", _sealBtn];

        _slots pushBack _sealBG;
        uiNamespace setVariable ["ACME_Thora_SlotBGs", _slots];
        uiNamespace setVariable ["ACME_Thora_SeparateClosureSlots", true];

        // The stock thoracostomy tick only knows about the legacy final tube slot. Keep the new seal half live with
        // its own tiny UI-only refresher so inventory changes while the panel is open update count, tint and enable
        // state immediately. It never changes patient state or consumes inventory.
        private _oldPFH = uiNamespace getVariable ["ACME_Thora_SealSlotPFH", -1];
        if (_oldPFH < 0) then {
            private _pfh = [{
                params ["", "_id"];
                disableSerialization;
                private _d = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
                if (isNull _d) exitWith {
                    [_id] call CBA_fnc_removePerFrameHandler;
                    uiNamespace setVariable ["ACME_Thora_SealSlotPFH", -1];
                    uiNamespace setVariable ["ACME_Thora_SeparateClosureSlots", false];
                };
                private _sealBG2 = controlNull;
                {
                    if ((_x getVariable ["thoraTool", ""]) == "seal") exitWith {_sealBG2 = _x;};
                } forEach (uiNamespace getVariable ["ACME_Thora_SlotBGs", []]);
                if (isNull _sealBG2) exitWith {};
                private _m = uiNamespace getVariable ["ACME_Thora_Medic", objNull];
                private _allowed = !isNull _m && {[_m, "thoracostomySeal", true] call ACME_fnc_procedureAllowed};
                private _n = if (_allowed) then {[_m, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem} else {0};
                private _held = uiNamespace getVariable ["ACME_Thora_Held", ""];
                private _selected = _held == "seal";
                private _available = _allowed && {_n > 0};
                private _ic = _sealBG2 getVariable ["thoraIcon", controlNull];
                if (!isNull _ic) then {
                    _ic ctrlSetTextColor (if (_selected) then {[0,0,0,1]} else {if (_available) then {[1,1,1,0.85]} else {[0.4,0.4,0.4,0.5]}});
                };
                private _cnt = _sealBG2 getVariable ["thoraCount", controlNull];
                if (!isNull _cnt) then {
                    _cnt ctrlSetStructuredText parseText format ["<t align='right' size='0.75' color='%1'>x%2</t>", if (_n > 0) then {"#ffffff"} else {"#ff6666"}, _n];
                };
                _sealBG2 setVariable ["thoraLocked", !_available];
                private _b = _sealBG2 getVariable ["thoraBtn", controlNull];
                if (!isNull _b) then {
                    _b setVariable ["thoraLocked", !_available];
                    _b ctrlEnable (_available || {_selected});
                    _b ctrlSetTooltip (if (_available || {_selected}) then {"Place a chest seal"} else {"Chest seal required"});
                };
            }, 0.10, []] call CBA_fnc_addPerFrameHandler;
            uiNamespace setVariable ["ACME_Thora_SealSlotPFH", _pfh];
        };
    };
};

// Set each tray slot icon to the side-appropriate texture. Only texture changes happen here so picked-up/locked
// tint remains owned by the selection and live-inventory code.
{
    private _tool = _x getVariable ["thoraTool", ""];
    private _ic = _x getVariable ["thoraIcon", controlNull];
    if (!isNull _ic) then {
        private _tex = switch (_tool) do {
            case "chlorhexidine": { format ["\acm_extended\ui\items\chlorhexidine_%1_ca.paa", _side] };
            case "scalpel":       { "\x\acm\addons\airway\ui\surgical_airway\inv_scalpel.paa" };
            case "finger":        { format ["\acm_extended\ui\items\thoracostomy_finger_%1_ca.paa", _side] };
            case "tube":          { format ["\acm_extended\ui\items\chest_tube_%1_placed_ca.paa", ["left", "right"] select (_side == "left")] };
            case "seal":          { "\x\acm\addons\breathing\ui\chestseal_ca.paa" };
            default { "" };
        };
        if (_tex != "") then { _ic ctrlSetText _tex; };
    };
} forEach (uiNamespace getVariable ["ACME_Thora_SlotBGs", []]);
