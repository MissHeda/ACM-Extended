// the brightness veil, kept on top of everything.
// call it as [] call ACME_fnc_ventVeilRaise.
// on why this exists: a statically declared control cannot stay above the panel, because ctrlcreate appends new
// controls above every static one. half this panel is built dynamically at runtime: the self-test ring and its
// percentage, the ALERTS and PARAMS custom layouts, the logbook rows, the graph, the alarm window and the level
// popup. all of them landed on top of a static veil and carried on at full brightness while the static parts
// behind them dimmed correctly. that is why the self-test ring stayed bright while everything around it went
// dark, and why the popups ignored the setting entirely.
// so the veil is dynamic too, and this function re-creates it whenever it is no longer the last control in the
// display. the check is cheap and self-healing: it does not need to know who created what or in which order, it
// only needs to know whether anything has been created since.

disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

// there is nothing to dim while the device is turned round, and re-creating the bands would only un-hide
// them.
if (uiNamespace getVariable ["ACME_vent_flipped", false]) exitWith {};

private _all = allControls _dlg;
if (_all isEqualTo []) exitWith {};

// the veil is a stack of bands rather than one rectangle. the screen has rounded corners, so a single rect either
// stops short of the edges and leaves slivers of lit bar showing, or covers them and puts square dark nubs out
// past the rounding. the bands follow the silhouette of the inlay, measured row by row off the decoded texture,
// so the veil ends exactly where the glass does.
// each band is [ytop, ybottom, xleft, xright] as fractions of the art extent, generated straight from the texture:
// one band per distinct row profile, with runs of identical rows collapsed. the first pass sampled the profile at
// a few points and interpolated, so a band could end up narrower than the widest row inside it and leave an
// uncovered sliver at the corners. now every band is at least as wide as every row it spans, with a 0.0012 bleed
// so adjacent bands cannot leave a hairline between them.
// the transparent window between the bars counts as full width, because that is the glass and it is the part that
// most needs covering. it is verified to tile from 0.0000 to 1.0000 with no gaps.
#define VEIL_BANDS [ \
    [0.0000, 0.0029, 0.0264, 0.8771], \
    [0.0029, 0.0057, 0.0149, 0.9805], \
    [0.0057, 0.0086, 0.0126, 0.9851], \
    [0.0086, 0.0115, 0.0080, 0.9874], \
    [0.0115, 0.0143, 0.0080, 0.9897], \
    [0.0143, 0.0172, 0.0057, 0.9920], \
    [0.0172, 0.0201, 0.0034, 0.9943], \
    [0.0201, 0.0229, 0.0011, 0.9966], \
    [0.0229, 0.0287, 0.0011, 0.9989], \
    [0.0287, 0.8682, 0.0000, 1.0000], \
    [0.8682, 0.8739, 0.0034, 0.9989], \
    [0.8739, 0.8854, 0.0011, 0.9989], \
    [0.8854, 0.8940, 0.0034, 0.9989], \
    [0.8940, 0.9255, 0.0011, 0.9989], \
    [0.9255, 0.9341, 0.0034, 0.9989], \
    [0.9341, 0.9427, 0.0011, 0.9989], \
    [0.9427, 0.9771, 0.0034, 0.9989], \
    [0.9771, 0.9799, 0.0057, 0.9989], \
    [0.9799, 0.9828, 0.0057, 0.9966], \
    [0.9828, 0.9857, 0.0080, 0.9943], \
    [0.9857, 0.9885, 0.0103, 0.9920], \
    [0.9885, 0.9914, 0.0126, 0.9897], \
    [0.9914, 0.9943, 0.0149, 0.9851], \
    [0.9943, 0.9971, 0.0172, 0.9828], \
    [0.9971, 1.0000, 0.0241, 0.9391] ]

private _veils = uiNamespace getVariable ["ACME_vent_veilCtls", []];
private _last  = if (_veils isEqualTo []) then { controlNull } else { _veils select ((count _veils) - 1) };
private _isTop = (!isNull _last) && {(_all select ((count _all) - 1)) isEqualTo _last};

if (!_isTop) then {
    { if (!isNull _x) then { ctrlDelete _x; }; } forEach _veils;
    _veils = [];
    (uiNamespace getVariable ["ACME_vent_veilRect", (uiNamespace getVariable ["ACME_vent_scrRect", [0,0,1,1]])])
        params ["_vx","_vy","_vw","_vh"];
    // pixel-snapped, edge to edge, and never overlapping. this is the whole difficulty with a banded veil: the bands
    // are translucent, so anywhere two of them overlap the alpha compounds and that strip draws darker than the
    // rest. two bands at 0.62 stack to 0.86. the previous build forced a minimum height on each band to stop the
    // hairline corner bands vanishing, which made them overlap their neighbors, and those overlaps are the bands
    // showing through on screen.
    // so no band is given a minimum and no band is allowed to overlap. instead each boundary is snapped to the pixel
    // grid and every band starts exactly where the previous one ended. a band that rounds to zero height is skipped
    // outright, and the neighbor that swallowed its pixel row covers it. the result tiles the screen exactly once,
    // with no seams, no gaps and no doubled alpha.
    private _prevBot = -1;
    private _pxH = pixelH max 0.0001;
    private _snap = { params ["_v"]; (round (_v / _pxH)) * _pxH };
    {
        _x params ["_t","_b","_l","_r"];
        private _top = if (_prevBot < 0) then { [_vy + _vh*_t] call _snap } else { _prevBot };
        private _bot = [_vy + _vh*_b] call _snap;
        // the outermost edges bleed one pixel outward, so the first and last texture rows cannot be lost to rounding.
        // that overhang lands on the bezel and is a single pixel.
        if (_forEachIndex isEqualTo 0) then { _top = _top - _pxH; };
        if (_forEachIndex isEqualTo ((count VEIL_BANDS) - 1)) then { _bot = _bot + _pxH; };
        if (_bot > _top) then {
            private _c = _dlg ctrlCreate ["RscText", -1];
            _c ctrlSetPosition [_vx + _vw*_l, _top, _vw*(_r - _l), _bot - _top];
            _c ctrlCommit 0;
            _veils pushBack _c;
            _prevBot = _bot;
        };
        // if _bot is at or below _top the band rounded away to nothing. _prevBot is left alone, so the next band simply
        // continues from the same edge and that row is covered by whoever gets it.
    } forEach VEIL_BANDS;
    uiNamespace setVariable ["ACME_vent_veilCtls", _veils];
    uiNamespace setVariable ["ACME_vent_veilC", []];  // force a repaint on the fresh controls.
};

// color.
// there are two regimes, decided by whether image intensifiers are up.
// to the naked eye the veil is black and gets heavier as the level falls, and level 1 is effectively gone in
// daylight.
// under nvg the tube amplifies whatever the panel emits. level 1 was built for that and stays readable, and
// everything above it is a flare: the panel is already bright, the tube gains it up, and the screen blows out to
// white. level 2 is barely usable and 3 and 4 are gone completely.
// thermal is excluded from both. a backlit lcd has almost no thermal signature, and reading a screen through a
// thermal tube is not a thing.
private _bl  = round (uiNamespace getVariable ["ACME_vent_brightness", 3]);
_bl = _bl max 1 min 4;
private _nvg = (currentVisionMode ACE_player) isEqualTo 1;

private _col = if (_nvg) then {
    if (_bl <= 1) then {
        // the one case the panel is meant to be readable in the dark. it is slightly heavier than it was, so even the
        // night setting is a squint rather than a comfortable read.
        [0, 0, 0, (missionNamespace getVariable ["ACME_vent_nightNvgVeil", 0.22])]
    } else {
        private _bloom = (missionNamespace getVariable ["ACME_vent_nvgBloom", [0, 0, 0.80, 0.96, 0.99]]);
        [1, 1, 1, (_bloom param [_bl, 0.96])]
    };
} else {
    private _dark = (missionNamespace getVariable ["ACME_vent_dayVeil", [0, 0.97, 0.62, 0.30, 0.0]]);
    [0, 0, 0, (_dark param [_bl, 0.30])]
};

private _cur = uiNamespace getVariable ["ACME_vent_veilC", []];
if !(_cur isEqualTo _col) then {
    { if (!isNull _x) then { _x ctrlSetBackgroundColor _col; _x ctrlCommit 0; }; } forEach _veils;
    uiNamespace setVariable ["ACME_vent_veilC", _col];
};
