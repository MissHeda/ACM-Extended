// the onload for the thoracostomy mini-game. it positions the body, the zone and the interaction surface using
// the same aspect-fix math as the chest seal, wires the ultrawide-safe coordinate surface, reusing
// ACME_fnc_chestSealMouseCoords by stashing to the shared acme_cs_evt and cal convention, because only one
// mini-game dialog is ever open at a time, creates the palpation feel-dot, and starts the tick pfh. increment 1
// is palpation only.
disableSerialization;
params ["_display"];
uiNamespace setVariable ["ACME_Thora_DLG", _display];
uiNamespace setVariable ["ACME_minigame_open", true];  // it gates the ACE flashlights self-action.
private _ecgPat = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
if (!isNull _ecgPat) then {[_ecgPat, "ui:thora:" + str clientOwner, true] call ACME_fnc_ecgJostleRequest;};

// diagnostic. it settles a question that has quietly poisoned several builds: does finddisplay resolve a display
// that was created with createdisplay, or only a dialog? every condition in this addon that gates on whether a
// minigame is open uses finddisplay, and if it returns null in display mode then all of them are silently
// false.
if (missionNamespace getVariable ["ACME_debug_enabled", false]) then {
    // the decisive question: does the sqf dialog command return true for a display we made with createdisplay?
    // ACE's keydown runs while {dialog} do { closedialog 0; } before it opens its menu. if dialog is true for our
    // panel, ACE closes it every single time, and display mode can never work. no setting, no ordering and no
    // condition changes that.
    // and it would still look like it half-worked, because ACE caches condition results through
    // clearconditioncaches. the flashlights entry would appear in the menu from a cache taken while the panel was
    // alive, one instant before ACE destroyed it. the menu opens, the entry is there, the panel is gone. which is
    // exactly what was reported.
};

// an escape hatch. it is non-negotiable for the display-mode spike.
// a dialog closes on esc for free and a display does not: esc would go to the pause menu and this panel would sit
// there behind it, and if the done button ever failed too, the player would be trapped inside a thoracostomy
// with no way out. that is not a bug you want to discover on a live server.
// so esc closes it explicitly, in both modes, and it is wired here rather than in config so it cannot be
// missed.
_display displayAddEventHandler ["KeyDown", {
    if (_this call ACME_fnc_minigameInput) exitWith {true};
    params ["", "_key"];
    if (_key == 1) exitWith {  // 1 is dik_escape.
        [86600] call ACME_fnc_minigameClose;
        true  // consume it, so the pause menu does not also open.
    };
    false
}];
[_display] call ACME_fnc_installLightKey;  // ctrl+win opens the flashlight picker.

call ACM_GUI_fnc_pauseMedicalMenuPFH;

private _isNum = { params ["_v"]; (_v isEqualType 0) && {finite _v} };

// fn_thoraFlip.sqf writes this same UI side. Keep one side source on reopen.
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
if !(_side in ["left", "right"]) then { _side = "right"; };
uiNamespace setVariable ["ACME_Thora_Side", _side];
uiNamespace setVariable ["ACME_Thora_OnZone", false];
uiNamespace setVariable ["ACME_Thora_Palpating", false];
uiNamespace setVariable ["ACME_Thora_CurUV", []];

uiNamespace setVariable ["ACME_Thora_ZoneRight", missionNamespace getVariable ["ACME_thora_zoneRight", [0.482, 0.443, 0.055, 0.050]]];
uiNamespace setVariable ["ACME_Thora_ZoneLeft",  missionNamespace getVariable ["ACME_thora_zoneLeft",  [0.515, 0.443, 0.055, 0.050]]];

private _af = 0.5625;
if ((pixelW > 0) && {pixelH > 0} && {(pixelW / pixelH) > 0.05} && {(pixelW / pixelH) < 4}) then { _af = pixelW / pixelH; };
uiNamespace setVariable ["ACME_Thora_AspectFix", _af];

private _szX = safeZoneX; private _szY = safeZoneY; private _szW = safeZoneW; private _szH = safeZoneH;
if !(([_szW] call _isNum) && {[_szH] call _isNum} && {_szW > 0} && {_szH > 0}) then { _szX = 0; _szY = 0; _szW = 1; _szH = 1; };
private _cx = _szX + (_szW / 2);
private _bodyH = _szH * 0.78;
private _bodyW = _bodyH * _af;
private _bodyX = _cx - (_bodyW / 2);
private _bodyY = _szY + (_szH * 0.08);
uiNamespace setVariable ["ACME_Thora_BodyRect", [_bodyX, _bodyY, _bodyW, _bodyH]];
// the unshaken resting rect. everything the cabin motion does is measured from here. see fn_motionshake.
uiNamespace setVariable ["ACME_Thora_BodyRectBase", [_bodyX, _bodyY, _bodyW, _bodyH]];

(_display displayCtrl 86601) ctrlSetPosition [_bodyX, _bodyY, _bodyW, _bodyH];
(_display displayCtrl 86601) ctrlCommit 0;
(_display displayCtrl 86604) ctrlSetPosition [_bodyX, _bodyY, _bodyW, _bodyH];
(_display displayCtrl 86604) ctrlCommit 0;

// reset the shared coordinate calibration, because we reuse the chest seal coord resolver, and wire the
// surface.
uiNamespace setVariable ["ACME_CS_EvtUI", []];
uiNamespace setVariable ["ACME_CS_EvtUITime", -1];
uiNamespace setVariable ["ACME_CS_CalXminG",  1e9];
uiNamespace setVariable ["ACME_CS_CalXmaxG", -1e9];
uiNamespace setVariable ["ACME_CS_CalYminG",  1e9];
uiNamespace setVariable ["ACME_CS_CalYmaxG", -1e9];
uiNamespace setVariable ["ACME_CS_CalXminU", 0];
uiNamespace setVariable ["ACME_CS_CalXmaxU", 0];
uiNamespace setVariable ["ACME_CS_CalYminU", 0];
uiNamespace setVariable ["ACME_CS_CalYmaxU", 0];

private _surface = _display displayCtrl 86610;
_surface ctrlSetPosition [_bodyX, _bodyY, _bodyW, _bodyH];
_surface ctrlCommit 0;
_surface ctrlEnable true;
_surface ctrlShow true;
private _fnTrack = {
    params ["_ctrl", "_ex", "_ey"];
    if !((_ex isEqualType 0) && {_ey isEqualType 0} && {finite _ex} && {finite _ey}) exitWith {};
    uiNamespace setVariable ["ACME_CS_EvtUI", [_ex, _ey]];
    uiNamespace setVariable ["ACME_CS_EvtUITime", diag_tickTime];
    getMousePosition params ["_gx", "_gy"];
    if !((_gx isEqualType 0) && {_gy isEqualType 0} && {finite _gx} && {finite _gy}) exitWith {};
    if (_gx < (uiNamespace getVariable ["ACME_CS_CalXminG",  1e9]))  then { uiNamespace setVariable ["ACME_CS_CalXminG", _gx]; uiNamespace setVariable ["ACME_CS_CalXminU", _ex]; };
    if (_gx > (uiNamespace getVariable ["ACME_CS_CalXmaxG", -1e9])) then { uiNamespace setVariable ["ACME_CS_CalXmaxG", _gx]; uiNamespace setVariable ["ACME_CS_CalXmaxU", _ex]; };
    if (_gy < (uiNamespace getVariable ["ACME_CS_CalYminG",  1e9]))  then { uiNamespace setVariable ["ACME_CS_CalYminG", _gy]; uiNamespace setVariable ["ACME_CS_CalYminU", _ey]; };
    if (_gy > (uiNamespace getVariable ["ACME_CS_CalYmaxG", -1e9])) then { uiNamespace setVariable ["ACME_CS_CalYmaxG", _gy]; uiNamespace setVariable ["ACME_CS_CalYmaxU", _ey]; };
};
_surface ctrlAddEventHandler ["MouseMoving", _fnTrack];
_surface ctrlAddEventHandler ["MouseHolding", _fnTrack];

// the feel-dot, reusing the chest seal dot art, sized from the body.
private _dh = _bodyH * 0.028;
uiNamespace setVariable ["ACME_Thora_DotH", _dh];
uiNamespace setVariable ["ACME_Thora_DotW", _dh * _af];

// the layer order, bottom to top, is the iodine prep, then the pink tract opening, then the red incision line,
// because later controls draw on top.
// the chlorhexidine prep trail pool is at the bottom.
private _prepDots = [];
for "_i" from 1 to 130 do {
    private _p = _display ctrlCreate ["ACME_CS_Dot", -1];
    _p ctrlEnable false;
    _p ctrlShow false;
    _prepDots pushBack _p;
};
uiNamespace setVariable ["ACME_Thora_PrepDots", _prepDots];
uiNamespace setVariable ["ACME_Thora_Prepping", false];

// the red incision line pool, drawn first, under the opening.
private _segs = [];
for "_i" from 1 to 24 do {
    private _s = _display ctrlCreate ["ACME_CS_Dot", -1];
    _s ctrlEnable false;
    _s ctrlShow false;
    _segs pushBack _s;
};
uiNamespace setVariable ["ACME_Thora_IncSegs", _segs];
uiNamespace setVariable ["ACME_Thora_Cutting", false];
uiNamespace setVariable ["ACME_Thora_CutLocked", false];

// the kelly and finger tract opening: a procedural rotated hole, with a dark center and a red rim, drawn as a
// filled ellipse of dots along the incision axis, and created after the incision so it sits on top. there is no
// map and no drawicon, so there is no gray square, and the rotation is exact because we compute the dot
// positions directly.
private _openSegs = [];
for "_i" from 1 to 90 do {
    private _o = _display ctrlCreate ["ACME_CS_Dot", -1];
    _o ctrlEnable false;
    _o ctrlShow false;
    _openSegs pushBack _o;
};
uiNamespace setVariable ["ACME_Thora_OpenSegs", _openSegs];

// a clean pre-baked hole frame, used when ACME_thora_useHoleFrames is true, on top of the procedural pool.
// the pink pleura bed, the split-open incision, is created before the dark hole so the hole draws inside and on
// top of it.
private _pleuraCtrl = _display ctrlCreate ["RscPicture", -1];
_pleuraCtrl ctrlEnable false;
_pleuraCtrl ctrlShow false;
uiNamespace setVariable ["ACME_Thora_PleuraCtrl", _pleuraCtrl];

private _openCtrl = _display ctrlCreate ["RscPicture", -1];
_openCtrl ctrlEnable false;
_openCtrl ctrlShow false;
uiNamespace setVariable ["ACME_Thora_OpenCtrl", _openCtrl];


// the right-side tool tray: the flip at the top, then the tools in the order of operations. the slot height is
// derived so the whole column, the flip plus 5 tools plus the gaps, fits above the done button, with the done
// button as the bottom padding. all are present by default and the medic selects each manually, because nothing
// auto-advances.
uiNamespace setVariable ["ACME_Thora_Held", ""];
private _top = _bodyY + (_bodyH * 0.02);
private _doneTop = _szY + (_szH * 0.92);
private _flipH = _szH * 0.040;
private _gapFlip = _szH * 0.015;
private _slotGap = _szH * 0.010;
private _botPad = _szH * 0.020;
private _slotsAvail = (_doneTop - _top - _botPad - _flipH - _gapFlip - (4 * _slotGap)) max (_szH * 0.35);
private _slotH = _slotsAvail / 5;
private _colW = _slotH * _af;
private _colX = _bodyX + _bodyW + (_bodyH * 0.035 * _af);

(_display displayCtrl 86626) ctrlSetPosition [_colX, _top, _colW, _flipH];
(_display displayCtrl 86626) ctrlCommit 0;
private _ty = _top + _flipH + _gapFlip;

private _tools = [
    ["chlorhexidine", "\acm_extended\ui\items\chlorhexidine_right_ca.paa"],
    ["scalpel",       "\x\acm\addons\airway\ui\surgical_airway\inv_scalpel.paa"],
    ["kelly",         "\acm_extended\ui\items\kelly_clamps_icon_ca.paa"],
    ["finger",        "\acm_extended\ui\items\thoracostomy_finger_right_ca.paa"],
    ["tube",          "\acm_extended\ui\items\chest_tube_right_placed_ca.paa"]
];
private _slotBGs = [];
private _inset = _slotH * 0.17;
// Resolve permissions and inventory for the captured provider, not a different UI target.
private _medic = uiNamespace getVariable ["ACME_Thora_Medic", objNull];
([_medic] call ACME_fnc_thoraClosureMode) params ["_closure", "_closureCount", "_canTube"];
private _hasSeal = _closureCount > 0;
uiNamespace setVariable ["ACME_Thora_CanTube", _canTube];
uiNamespace setVariable ["ACME_Thora_SealMode", !_canTube];
{
    _x params ["_tool", "_icon"];
    private _isTube = (_tool == "tube");
    // locked only when there is nothing at all to close the chest with. otherwise the tube slot is a seal slot.
    private _toolLocked = (_isTube && {!_canTube} && {!_hasSeal});
    private _bg = _display ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [_colX, _ty, _colW, _slotH];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.85];
    _bg setVariable ["thoraTool", _tool];
    _bg setVariable ["thoraLocked", _toolLocked];
    _bg ctrlCommit 0;
    _slotBGs pushBack _bg;

    private _icX = _colX + _inset; private _icY = _ty + _inset;
    private _icW = _colW - (2 * _inset); private _icH = _slotH - (2 * _inset);
    private _ic = _display ctrlCreate ["RscPicture", -1];
    _ic ctrlSetPosition [_icX, _icY, _icW, _icH];
    _ic ctrlSetText _icon;
    // locked, with no kit, is dim gray, and usable is normal.
    _ic ctrlSetTextColor (if (_toolLocked) then {[0.4, 0.4, 0.4, 0.5]} else {[1, 1, 1, 0.85]});
    _ic ctrlCommit 0;
    _bg setVariable ["thoraIcon", _ic];

    // the count, on the slot that consumes something.
    // the tube slot is the only one that spends an item, and which item it spends depends on whether this provider
    // can tube at all. so it carries a count in the corner, the same way the airway and iv trays do, and it is
    // refreshed live in fn_thoratick rather than being read once at open.
    // live matters here: a medic can seal one side, walk to the other and find they are out, and a number that was
    // correct when the screen opened would be a lie by then.
    if (_isTube) then {
        private _cnt = _display ctrlCreate ["RscStructuredText", -1];
        _cnt ctrlSetPosition [_colX, _ty + (_slotH * 0.60), _colW - (_slotH * 0.06), _slotH * 0.36];
        _cnt ctrlCommit 0;
        _bg setVariable ["thoraCount", _cnt];
        uiNamespace setVariable ["ACME_Thora_CountCtrl", _cnt];
    };

    private _btn = _display ctrlCreate ["ACME_Thora_SlotBtn", -1];
    _btn ctrlSetPosition [_colX, _ty, _colW, _slotH];
    _btn ctrlSetText "";
    // the tooltip has to say the true reason. "chest tube kit required" was wrong for a medic who has the kit and
    // not the trait, and wrong again for one who simply has no seal left.
    _btn ctrlSetTooltip (if (!_toolLocked) then {
        if (_isTube && {!_canTube}) then {"Place a chest seal"} else {format ["Select %1", _tool]}
    } else {
        "No chest seal and no chest tube kit"
    });
    _btn setVariable ["thoraTool", _tool];
    _btn setVariable ["thoraLocked", _toolLocked];
    _btn setVariable ["thoraIcon", _ic];
    _btn setVariable ["thoraBG", _bg];
    _btn setVariable ["thoraIconRect", [_icX, _icY, _icW, _icH]];
    _btn ctrlSetBackgroundColor [0, 0, 0, 0];
    // a locked tool button is disabled, so it is not clickable and does not highlight on hover.
    // the handlers are attached either way, and only the enable state changes. the tube slot can lock and unlock
    // while the screen is open, when the last seal is used or a kit is picked up, and a button that had no
    // handler attached at open would stay dead however many times it was later enabled.
    _btn setVariable ["thoraBtnSelf", _btn];
    _bg setVariable ["thoraBtn", _btn];
    _btn ctrlEnable (!_toolLocked);
    if (true) then {
        _btn ctrlAddEventHandler ["ButtonClick", { [(_this select 0) getVariable ["thoraTool", ""]] call ACME_fnc_thoraSelectTool; }];
        _btn ctrlAddEventHandler ["MouseEnter", { [(_this select 0), true] call ACME_fnc_thoraSlotHover; }];
        _btn ctrlAddEventHandler ["MouseExit", { [(_this select 0), false] call ACME_fnc_thoraSlotHover; }];
    };
    _btn ctrlCommit 0;

    _ty = _ty + _slotH + _slotGap;
} forEach _tools;
uiNamespace setVariable ["ACME_Thora_SlotBGs", _slotBGs];
[] call ACME_fnc_thoraUpdateTrayIcons;

// the held-tool cursor sprite. it floats with the mouse and is created last so it sits on top. the side-specific
// textures use %1 for right or left. the sizes are body-height fractions from the reference photos, and they are
// tunable.
private _toolSpr = _display ctrlCreate ["RscPicture", -1];
_toolSpr ctrlEnable false;
_toolSpr ctrlShow false;
uiNamespace setVariable ["ACME_Thora_ToolSpr", _toolSpr];
uiNamespace setVariable ["ACME_Thora_TubeSnap", false];
private _tubeCtrl = _display ctrlCreate ["RscPicture", -1];
_tubeCtrl ctrlEnable false;
_tubeCtrl ctrlShow false;
uiNamespace setVariable ["ACME_Thora_TubeCtrl", _tubeCtrl];

// the palpation feel-dot is created last, so it draws on top of everything and you can feel over the incision and
// the opening.
private _dot = _display ctrlCreate ["ACME_CS_Dot", -1];
_dot ctrlEnable false;
_dot ctrlShow false;
uiNamespace setVariable ["ACME_Thora_Dot", _dot];
uiNamespace setVariable ["ACME_Thora_SprData", createHashMapFromArray [
    ["chlorhexidine", ["\acm_extended\ui\items\chlorhexidine_%1_ca.paa", 0.20]],
    ["scalpel",       ["\x\acm\addons\airway\ui\surgical_airway\active_scalpel_h.paa", 0.34]],
    ["kelly",         ["\acm_extended\ui\items\kelly_clamps_closed_ca.paa", 0.26]],
    ["finger",        ["\acm_extended\ui\items\thoracostomy_finger_%1_ca.paa", 0.40]],
    ["tube",          ["\acm_extended\ui\items\chest_tube_%1_placed_ca.paa", 0.34]],
    ["seal",          ["\x\acm\addons\breathing\ui\chestseal_ca.paa", 0.18]]
]];

[] call ACME_fnc_thoraRender;

private _pfh = [ACME_fnc_thoraTick, 0, []] call CBA_fnc_addPerFrameHandler;
uiNamespace setVariable ["ACME_Thora_PFH", _pfh];
_display displayAddEventHandler ["MouseButtonDown", {_this call ACME_fnc_thoraMouseDown}];
_display displayAddEventHandler ["MouseButtonUp", {_this call ACME_fnc_thoraMouseUp}];
