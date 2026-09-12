// full-screen darkness with a torch on your cursor.
// this is a direct port of ace_map_fnc_simulatemaplight, which is what lights the ACE map, done with dialog
// controls instead of drawicon because we are not on a map control.
// how ACE does it is not what you would guess. arma's 2d ui has no blend modes, so you cannot paint a light onto
// black to reveal what is under it. drawing something bright over black just gives you a bright smear on top of
// the art. there is no additive blend, no mask and no cutout.
// so the flashlight is not a light at all. it is a hole in the darkness.
// ACE's Flashlight_Beam_white_ca.paa is a shade texture: opaque black at the edges and transparent in the middle.
// drawn black over the panel it darkens everything except its own center, and that transparent center is the
// beam. then four solid black rectangles are drawn around it to fill the rest of the screen. that is the whole
// trick, and it is why the pool in the ACE screenshot has a soft round falloff rather than a hard edge.
// we use ACE's own texture, ACE's own light-level function, fnc_determinemaplight, so our darkness is exactly the
// map's darkness, and ACE's own per-flashlight beam size from config. nothing here is reinvented, because a
// light that behaves differently here than on the map would be worse than no light at all.
// call it as [_display, _rect, _key] call ACME_fnc_darknessShade. _rect is legacy and ignored, because this is
// full-screen.
params ["_display", "_rect", "_key"];
if (isNull _display) exitWith {};
if ((currentVisionMode ACE_player == 1 && {hmd ACE_player != ""})
    || {!(missionNamespace getVariable ["ACME_darkness_enable", true])}) exitWith {
    private _old = uiNamespace getVariable [_key, []];
    if (_old isEqualType []) then {{if (!isNull _x) then {_x ctrlShow false;};} forEach _old;};
};

// ACE's own lighting maths, so the panel darkens exactly as the map does. if ACE's map component is somehow not
// there, do nothing rather than throw. no darkness is an annoyance and an error every frame is a broken
// mission.
if (isNil "ace_map_fnc_determineMapLight") exitWith {};
([ACE_player] call ace_map_fnc_determineMapLight) params [["_apply", false], ["_lightLevel", [0,0,0,0]]];
if (!(_lightLevel isEqualType []) || {(count _lightLevel) < 4}) exitWith {};
private _ctrls = uiNamespace getVariable [_key, []];
// a type guard, and it is not paranoia. an older build stored a single control under this key, and the rewrite
// stores an array of thirteen. uinamespace survives a mission restart, so anyone who had the old build loaded
// this session still has a lone control sitting here, and count <control> throws every frame. anything that is
// not an array is from a previous life, so bin it and rebuild.
if (!(_ctrls isEqualType [])) then { _ctrls = []; };

_lightLevel params ["_lr", "_lg", "_lb", "_shadeAlpha"];
// no darkening asked for, which is daylight, a bright light source or an enclosed cabin. it still goes through
// the smoothing below as a zero, rather than hiding the panels on the spot, so a single odd sample cannot flash
// the shade off and back on.
if (!_apply) then { _shadeAlpha = 0; _lr = 1; _lg = 1; _lb = 1; };

// a cabin is not a light source, and a buttoned-up one does get a little instrument glow.
private _veh = vehicle ACE_player;
if (!(_veh isEqualTo ACE_player) && {!(isTurnedOut ACE_player)}) then {
    private _open = [_veh] call ACME_fnc_vehicleOpenness;
    private _relief = missionNamespace getVariable ["ACME_darkness_cabinRelief", 0.88];
    _shadeAlpha = _shadeAlpha * (_relief + ((1 - _relief) * _open));
};
// push it to actual black.
// ACE's own curve tops out around 0.86 at a moonlit ambient, because the map only needs to be hard to read rather
// than invisible. a minigame is a different problem: 10 to 14 percent of a bright white body image is still a
// perfectly legible silhouette, which is precisely what you were looking at. so boost ACE's alpha and clamp,
// which takes a moonlit night to a true 1.0, with nothing at all, no shape and no outline, while leaving dusk
// and daylight sensible.
_shadeAlpha = (_shadeAlpha * (missionNamespace getVariable ["ACME_darkness_boost", 1.25])) min 1;
_shadeAlpha = (_shadeAlpha * (missionNamespace getVariable ["ACME_darkness_maxAlpha", 1.0])) min 1;

// steady the reading.
// getlightingat, which is what ACE reads, samples the engine light probe and does not return the same answer
// every frame. the dynamic component in particular swings, so the raw alpha walks across ACE's brightness bands
// and the panel visibly pulses dark and light on its own with no light source anywhere near the medic.
// a median over the last few seconds fixes that properly. an average would still be dragged by a run of outliers
// and would only slow the pulse down. a median ignores them outright, and the shade only moves when the light
// genuinely has.
// sampling is rate limited as well, which also keeps getlightingat off the per-frame path.
private _histKey = format ["ACME_darkness_hist_%1", _key];
private _stampKey = format ["ACME_darkness_stamp_%1", _key];
private _now = diag_tickTime;
private _hist = uiNamespace getVariable [_histKey, []];
if (!(_hist isEqualType [])) then { _hist = []; };
private _period = missionNamespace getVariable ["ACME_darkness_samplePeriod", 0.2];
private _window = missionNamespace getVariable ["ACME_darkness_smoothWindow", 3];
private _keep = 1 max (round (_window / (_period max 0.05)));
// a gap in the calls means the panel was closed and reopened, so the old window is stale. start it again rather
// than spend the first seconds of a new panel fading from whatever the light was when the last one shut.
private _lastAt = uiNamespace getVariable [_stampKey, -1e9];
if ((_now - _lastAt) > (missionNamespace getVariable ["ACME_darkness_sessionGap", 2])) then {
    _hist = [];
    uiNamespace setVariable [_histKey, _hist];
};
if ((_now - _lastAt) >= _period) then {
    uiNamespace setVariable [_stampKey, _now];
    _hist pushBack _shadeAlpha;
    while {count _hist > _keep} do { _hist deleteAt 0; };
    uiNamespace setVariable [_histKey, _hist];
};
if (count _hist > 0) then {
    private _sorted = +_hist;
    _sorted sort true;
    _shadeAlpha = _sorted select (floor ((count _sorted) / 2));
};

// NV close-focus presentation is applied after procedural rendering.
if (_shadeAlpha <= 0.01) exitWith {
    { if (!isNull _x) then { _x ctrlShow false; }; } forEach _ctrls;
};

// Procedural marks append later than the original shade. Recreate only the six
// inert shade controls when actual artwork has overtaken them in creation order.
// Exclude all visual overlays to avoid a rebuild loop with held-tool raising.
private _dWas = uiNamespace getVariable [_key + "_dlg", displayNull];
private _all = allControls _display;
private _stale = (_dWas isNotEqualTo _display) || {count _ctrls != 6} || {(_ctrls findIf {isNull _x}) >= 0};
if (!_stale) then {
    private _firstShade = _all find (_ctrls select 0);
    private _lastArt = -1;
    {if !(_x getVariable ["ACME_NV_OverlayControl", false]) then {_lastArt = _forEachIndex;};} forEach _all;
    _stale = _firstShade < 0 || {_lastArt > _firstShade};
};
if ((count _ctrls) < 6 || {_stale}) then {
    { if (!isNull _x) then { ctrlDelete _x; }; } forEach _ctrls;
    _ctrls = [];
    private _tint = _display ctrlCreate ["RscText", -1];  // 0: the ambient color wash.
    _tint ctrlEnable false;
    _ctrls pushBack _tint;
    private _beam = _display ctrlCreate ["RscPicture", -1];  // 1: the shade-with-a-hole. this is the flashlight.
    _beam ctrlEnable false;
    _ctrls pushBack _beam;
    for "_i" from 1 to 4 do {  // 2 to 5: fill the rest of the screen with black.
        private _f = _display ctrlCreate ["RscText", -1];
        _f ctrlEnable false;
        _ctrls pushBack _f;
    };
    {_x setVariable ["ACME_NV_OverlayControl", true];} forEach _ctrls;
    uiNamespace setVariable [_key, _ctrls];
    uiNamespace setVariable [_key + "_dlg", _display];
    // the shake caches control handles by count, and we just changed it, so make it recapture.
    { uiNamespace setVariable [_x, []]; } forEach ["ACME_IV_ShakeBase", "ACME_CS_ShakeBase", "ACME_Thora_ShakeBase", "ACME_Laryngo_ShakeBase"];
};

private _L = safeZoneX;
private _T = safeZoneY;
private _W = safeZoneW;
private _H = safeZoneH;

// the ambient color wash: ACE's own normalized light color, so a moonlit night reads blue and a fire reads
// warm.
private _maxC = selectMax [_lr, _lg, _lb];
// the color wash must never be brighter than the darkness it sits under, or dialling the boost down makes the
// panel lighter than ACE's map, which would be a strange thing to have built.
private _cAlpha = (((_lr + _lg + _lb) min _shadeAlpha) * (1 - _shadeAlpha)) max 0;
// with the goggles up the wash is the effect rather than a tint on top of the black, so it carries its own
// strength instead of being scaled down by a shade alpha that is nearly gone.

private _amb = if (_maxC == 0) then {[1, 1, 1, _cAlpha]} else {[_lr / _maxC, _lg / _maxC, _lb / _maxC, _cAlpha]};
private _tint = _ctrls select 0;
_tint ctrlSetPosition [_L, _T, _W, _H];
_tint ctrlSetBackgroundColor _amb;
_tint ctrlCommit 0;
_tint ctrlShow true;

private _flashlight = (ACE_player getVariable ["ace_map_flashlight", ["", objNull]]) select 0;

// the alpha is ACE's determinemaplight value, times the legibility boost above, and nothing else. the
// dark-adaptation model that used to live here, with its rhodopsin bleach table, its dilate and constrict
// easing and the adaptrelief lift, is gone. it was the one thing this file had that ACE's map does not, and it
// moved the alpha frame to frame while the base light was steady, which is the pulsing. ACE reads the ambient
// light and draws the shade, full stop.
private _beam = _ctrls select 1;

if (_flashlight isEqualTo "") then {
    // no light: flat black over everything. you are not almost blind, you are blind. go and find a torch.
    _beam ctrlShow false;
    private _f = _ctrls select 2;
    _f ctrlSetPosition [_L, _T, _W, _H];
    _f ctrlSetBackgroundColor [0, 0, 0, _shadeAlpha];
    _f ctrlCommit 0;
    _f ctrlShow true;
    { (_ctrls select _x) ctrlShow false; } forEach [3, 4, 5];
} else {
    // the beam, straight out of the flashlight's own config, exactly as ACE reads it.
    private _cfg = _flashlight call CBA_fnc_getItemConfig;
    if (isClass (_cfg >> "ItemInfo")) then { _cfg = _cfg >> "ItemInfo"; };
    _cfg = _cfg >> "FlashLight";
    private _size = [_cfg >> "ACE_Flashlight_Size", "number", 2.75] call CBA_fnc_getConfigEntry;
    private _tex  = [_cfg >> "ACE_Flashlight_Beam", "text",
        "\z\ace\addons\map\UI\Flashlight_Beam_white_ca.paa"] call CBA_fnc_getConfigEntry;

    // the beam diameter as a fraction of screen height, scaled by that torch's own size value, so a bigger _size is a
    // tighter beam, the same as ACE. a maglite throws a wider pool than a weapon light, and that is a real
    // difference.
    private _d = _H * ((missionNamespace getVariable ["ACME_darkness_beamScale", 1.55]) / _size);

    // square in pixels. x and y ui units are not the same physical size, which is why the old pool came out as a
    // stretched ellipse on a 32:9 screen. pixelw over pixelh is the ratio this addon already uses for its body
    // rects.
    private _af = 1;
    if (pixelH != 0) then { _af = pixelW / pixelH; };
    private _dw = _d * _af;

    // the beam is the cursor, always. it is the medic's own torch pointing where they are looking, and pinning it to
    // an instrument was wrong, because it made the light appear to switch itself on and follow the blade around the
    // moment the blade went in, which is not what a handheld torch does.
    private _m = getMousePosition;
    if !((_m isEqualType []) && {(count _m) >= 2}) exitWith {
        { if (!isNull _x) then { _x ctrlShow false; }; } forEach _ctrls;
    };
    _m params ["_cx", "_cy"];
    if !((_cx isEqualType 0) && {finite _cx} && {finite _cy}) exitWith {
        { if (!isNull _x) then { _x ctrlShow false; }; } forEach _ctrls;
    };

    private _bx = _cx - (_dw / 2);
    private _by = _cy - (_d  / 2);

    // a stale duplicate of the instrument-light block used to sit here. it ran before _c2 was declared and painted
    // the control black with an undefined alpha, which is the gray square that appeared over the mouth whenever the
    // blade lamp came on. the working copy is below, after the fills, where it belongs.

    // the shade-with-a-hole, centerd on the cursor. it follows the mouse every frame, because it is the mouse.
    _beam ctrlSetText _tex;
    _beam ctrlSetPosition [_bx, _by, _dw, _d];
    _beam ctrlSetTextColor [1, 1, 1, _shadeAlpha];
    _beam ctrlCommit 0;
    _beam ctrlShow true;

    // four solid fills around the beam, so everything outside the pool is black. they are the same four ACE
    // draws.
    private _fnFill = {
        params ["_c", "_x", "_y", "_w", "_h"];
        if (isNull _c) exitWith {};
        if (_w <= 0 || {_h <= 0}) exitWith { _c ctrlShow false; };
        _c ctrlSetPosition [_x, _y, _w, _h];
        _c ctrlSetBackgroundColor [0, 0, 0, _shadeAlpha];
        _c ctrlCommit 0;
        _c ctrlShow true;
    };
    private _top = _by max _T;
    private _bot = (_by + _d) min (_T + _H);

    [(_ctrls select 2), _L, _T, _W, _top - _T] call _fnFill;  // above.
    [(_ctrls select 3), _L, _bot, _W, (_T + _H) - _bot] call _fnFill;  // below.
    [(_ctrls select 4), _L, _top, (_bx max _L) - _L, _bot - _top] call _fnFill;  // left.
    [(_ctrls select 5), (_bx + _dw) min (_L + _W), _top,
        (_L + _W) - ((_bx + _dw) min (_L + _W)), _bot - _top] call _fnFill;  // right.

    // a bespoke second light pool for the laryngoscope blade lived here across three builds and produced a gray
    // square, then a red flicker. it is gone. the blade lamp is not special: the medic turns their flashlight on
    // with the same ACE picker every other minigame uses, and that has always worked.
};
