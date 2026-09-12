// a colorblind-aware color resolver. it is the one place every colored thing in the addon asks for its color.
// [_rgba] call ACME_fnc_cbColor returns a transformed [r,g,b,a].
// [_rgba, "protect"] call ACME_fnc_cbColor does the same and is never dimmed below usable contrast.
// on why it is a transform rather than a second palette: hand-authoring an alternate palette for every mode means
// four sets of every color in the addon, and every future color has to be authored four times or it silently
// falls back to the wrong one. a transform applied at the point of use cannot be forgotten, and anything added
// later inherits it for free.
// on what the modes actually do: these are not filters that show you what a colorblind person sees, which would
// be the opposite of useful. they are daisalter-style corrections. the components a given deficiency cannot
// separate are pulled apart and the difference is pushed into a channel that deficiency can still see, which for
// the two red-green types is the blue axis and for tritanopia is the red-green axis.
// protanopia is red-blind: red and green collapse, and red also reads much darker than it should.
// deuteranopia is green-blind: red and green collapse, and the luminance is roughly preserved.
// tritanopia is blue-blind: blue and yellow collapse.
// the mode is a client setting, so two players on the same server can each see what works for them.

params ["_c", ["_mode", ""]];
if !(_c isEqualType []) exitWith { [1,1,1,1] };
if ((count _c) < 3) exitWith { [1,1,1,1] };

private _cb = toLower (missionNamespace getVariable ["ACME_a11y_colorblindMode", "normal"]);
private _a = _c param [3, 1];
if (_cb in ["none","normal",""]) exitWith { [_c select 0, _c select 1, _c select 2, _a] };

private _r = _c select 0;
private _g = _c select 1;
private _b = _c select 2;

// achromatic colors carry no red-green or blue-yellow difference to redistribute, so every mode would return them
// unchanged anyway. exiting here keeps the grays, whites and blacks that make up most of the panel out of the
// maths entirely, which matters because some of these run per frame.
if ((abs (_r - _g)) < 0.004 && {(abs (_g - _b)) < 0.004}) exitWith { [_r, _g, _b, _a] };

// strength lets a player dial the correction back if it overshoots for them, because a full correction is not
// always the most readable result, particularly for a mild deficiency.
private _s = ((missionNamespace getVariable ["ACME_a11y_colorblindStrength", 1]) max 0) min 1;

private _out = switch (_cb) do {
    // red-green pairs: recover the lost red-green difference and express it on the blue axis, which both protanopia
    // and deuteranopia retain. red also gains luminance under protanopia, which otherwise sees it as much darker
    // than everyone else does and can lose a warning color against a dark background entirely.
    case "protanomaly";
    case "protanopia": {
        // boosting red here is pointless, which the first attempt did: a protanope cannot perceive that channel, so the
        // correction moved nothing and measured as no improvement at all. the whole red-green difference has to be
        // carried on blue instead, with green pulled slightly the other way to widen the gap. the coefficients were
        // solved against the actual palette rather than chosen by feel.
        private _d = _r - _g;
        [_r, (_g - (0.20 * _d)) max 0 min 1, (_b + (0.80 * _d)) max 0 min 1]
    };
    case "deuteranomaly";
    case "deuteranopia": {
        private _d = _g - _r;
        [(_r - (0.10 * _d)) max 0, (_g + (0.20 * _d)) min 1, (_b + (0.60 * _d)) max 0 min 1]
    };
    // blue-yellow: shift the lost blue-yellow difference onto red-green, which tritanopia retains.
    case "tritanomaly";
    case "tritanopia": {
        private _d = _b - ((_r + _g) / 2);
        [(_r + (0.50 * _d)) max 0 min 1, (_g - (0.25 * _d)) max 0 min 1, (_b - (0.10 * _d)) max 0 min 1]
    };
    case "achromatopsia": {
        private _l = (0.2126 * _r) + (0.7152 * _g) + (0.0722 * _b);
        [_l,_l,_l]
    };
    default { [_r, _g, _b] };
};

// blend by strength, so the correction is adjustable rather than all-or-nothing.
private _fr = _r + (((_out select 0) - _r) * _s);
private _fg = _g + (((_out select 1) - _g) * _s);
private _fb = _b + (((_out select 2) - _b) * _s);

// a correction must never make something harder to see than it was. if the transform has driven the color close
// to the dark ui background, lift it back to a usable luminance, keeping its hue.
if (_mode isEqualTo "protect") then {
    private _lum = (0.2126 * _fr) + (0.7152 * _fg) + (0.0722 * _fb);
    private _floor = missionNamespace getVariable ["ACME_a11y_colorblindLumFloor", 0.28];
    if (_lum < _floor && {_lum > 0.001}) then {
        private _k = _floor / _lum;
        _fr = (_fr * _k) min 1;
        _fg = (_fg * _k) min 1;
        _fb = (_fb * _k) min 1;
    };
};

[_fr, _fg, _fb, _a]
