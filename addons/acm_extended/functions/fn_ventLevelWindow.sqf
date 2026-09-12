// the level popup. brightness and alarm volume are set in a window that opens over whatever screen you are on,
// exactly the way the alarm window does, rather than on a screen of their own.
// ["brightness"] call ACME_fnc_ventLevelWindow opens, or repaints, the brightness popup.
// ["alarmvol"] call ACME_fnc_ventLevelWindow opens, or repaints, the volume popup.
// ["repaint"] call ACME_fnc_ventLevelWindow redraws in place, after the dial moved the level.
// ["close"] call ACME_fnc_ventLevelWindow tears it down.
// there are four levels, drawn as four bars of increasing height. the bars up to and including the current level
// are filled and the rest are outlines. the height as well as the count carries the value, so it reads at a
// glance and is still readable to someone who cannot separate the fill color from the background.
// on why it is a popup rather than a screen: both of these settings change something you are looking at while you
// set it. brightness changes the panel itself, and volume you judge by ear against the alarm that is sounding.
// leaving the underlying screen visible behind the window is the point.
// night is level 1. the robust night setting is kept as the lowest of the four rather than dropped to make room,
// because it is the whole reason the brightness control is interesting: it drops the panel below naked-eye
// readable and lifts back under image intensifiers. four levels, and the bottom one is still night.

#define LVL_MIN 1
#define LVL_MAX 4

params [["_mode", ""]];
disableSerialization;

private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

// tear down whatever is up. every path rebuilds, so there is never a stale control left behind.
private _old = uiNamespace getVariable ["ACME_vent_lvlWin", []];
{ if (!isNull _x) then { ctrlDelete _x; }; } forEach _old;
uiNamespace setVariable ["ACME_vent_lvlWin", []];

if (_mode isEqualTo "close") exitWith {
    uiNamespace setVariable ["ACME_vent_lvlWinOpen", false];
    uiNamespace setVariable ["ACME_vent_lvlKind", ""];
};

private _kind = if (_mode isEqualTo "repaint") then {
    uiNamespace getVariable ["ACME_vent_lvlKind", "brightness"]
} else { _mode };
if !(_kind in ["brightness", "alarmvol"]) exitWith {
    uiNamespace setVariable ["ACME_vent_lvlWinOpen", false];
};

uiNamespace setVariable ["ACME_vent_lvlKind", _kind];
uiNamespace setVariable ["ACME_vent_lvlWinOpen", true];

private _isBright = (_kind isEqualTo "brightness");
private _title = if (_isBright) then { "BRIGHTNESS" } else { "ALARM VOLUME" };
private _lvl = if (_isBright) then {
    uiNamespace getVariable ["ACME_vent_brightness", 3]
} else {
    uiNamespace getVariable ["ACME_vent_alarmVol", 3]
};
_lvl = (round _lvl) max LVL_MIN min LVL_MAX;

(uiNamespace getVariable ["ACME_vent_scrRect", [0,0,1,1]]) params ["_sx","_sy","_sw","_sh"];
private _made = [];

// the window fills the content area between the bars of the inlay, the same footprint the alarm window uses.
private _wx = _sx + _sw * 0.02;
private _wy = _sy + _sh * 0.150;
private _ww = _sw * 0.96;
// the height is derived from the stack below rather than guessed, so the ok button can never run past the foot:
// the title strip at 0.115, plus a gap, plus the bars at 0.330, plus the ticks, plus a gap, plus the button at
// 0.115, all inside 0.700.
private _wh = _sh * 0.700;

// colors. every one goes through ventcolor, so brightness and the colorblind transform reach them. the fill is
// the cyan of the device, the same ink the battery uses, so the panel keeps one accent rather than inventing
// another.
private _ink   = [[0, 0.988, 0.992, 1]] call ACME_fnc_ventColor;
private _dim   = [[0, 0.988, 0.992, 0.28]] call ACME_fnc_ventColor;
private _panel = [[0, 0, 0, 1]] call ACME_fnc_ventColor;
private _white = [[1, 1, 1, 1]] call ACME_fnc_ventColor;
private _dark  = [[0.05, 0.05, 0.05, 1]] call ACME_fnc_ventColor;

// the panel.
private _bg = _dlg ctrlCreate ["RscText", -1];
_bg ctrlSetBackgroundColor _panel;
_bg ctrlSetPosition [_wx, _wy, _ww, _wh];
_bg ctrlCommit 0;
_made pushBack _bg;

// the title, on a white strip across the top of the panel.
private _tBg = _dlg ctrlCreate ["RscText", -1];
_tBg ctrlSetBackgroundColor _white;
_tBg ctrlSetPosition [_wx, _wy, _ww, _sh * 0.115];
_tBg ctrlCommit 0;
_made pushBack _tBg;

private _tTx = _dlg ctrlCreate ["ACME_VentTextC", -1];
_tTx ctrlSetText _title;
_tTx ctrlSetTextColor _dark;
_tTx ctrlSetBackgroundColor [0,0,0,0];
_tTx ctrlSetFontHeight (_sh * 0.085);
_tTx ctrlSetPosition [_wx, _wy + _sh * 0.012, _ww, _sh * 0.095];
_tTx ctrlCommit 0;
_made pushBack _tTx;

// the four bars.
// the bars sit on a baseline with a gap between each. bar n is n over LVL_MAX of the available height, so the
// silhouette rises left to right and the current level is both how many are filled and how tall the last filled
// one is.
// the bars occupy the middle band only. they used to run to 0.470 of the screen height from 0.150, which put their
// feet straight through the ok button underneath. they are shorter and lifted, so the button has its own clear
// strip.
private _barsY0 = _wy + _sh * 0.145;
private _barsH  = _sh * 0.330;
private _barsX0 = _wx + _ww * 0.09;
private _barsW  = _ww * 0.82;
private _slotW  = _barsW / LVL_MAX;
private _gap    = _slotW * 0.28;
private _barW   = _slotW - _gap;

for "_i" from 1 to LVL_MAX do {
    private _frac = _i / LVL_MAX;
    private _bh = _barsH * (0.28 + 0.72 * _frac);
    private _bx = _barsX0 + (_i - 1) * _slotW + _gap * 0.5;
    private _by = _barsY0 + (_barsH - _bh);

    private _b = _dlg ctrlCreate ["RscText", -1];
    _b ctrlSetBackgroundColor (if (_i <= _lvl) then { _ink } else { _dim });
    _b ctrlSetPosition [_bx, _by, _barW, _bh];
    _b ctrlCommit 0;
    _made pushBack _b;

    // a tick under each bar, so the scale is readable even at level 1 with one bar lit.
    private _tk = _dlg ctrlCreate ["RscText", -1];
    _tk ctrlSetBackgroundColor _white;
    _tk ctrlSetPosition [_bx, _barsY0 + _barsH + _sh * 0.012, _barW, _sh * 0.008];
    _tk ctrlCommit 0;
    _made pushBack _tk;
};

// the confirm button.
// there is one button, always selected, so the dial is free to do nothing but change the level. a middle-click
// confirms and closes, which is the only way out and matches the single tick in the reference.
private _okW = _ww * 0.26;
private _okX = _wx + (_ww - _okW) / 2;
// it sits below the bars and their ticks with a clear gap, rather than on top of them.
private _okY = _barsY0 + _barsH + _sh * 0.055;

private _okBg = _dlg ctrlCreate ["RscText", -1];
_okBg ctrlSetBackgroundColor _ink;
_okBg ctrlSetPosition [_okX, _okY, _okW, _sh * 0.115];
_okBg ctrlCommit 0;
_made pushBack _okBg;

private _okTx = _dlg ctrlCreate ["ACME_VentTextC", -1];
_okTx ctrlSetText "OK";
_okTx ctrlSetTextColor _dark;
_okTx ctrlSetBackgroundColor [0,0,0,0];
_okTx ctrlSetFontHeight (_sh * 0.080);
_okTx ctrlSetPosition [_okX, _okY + _sh * 0.014, _okW, _sh * 0.090];
_okTx ctrlCommit 0;
_made pushBack _okTx;

uiNamespace setVariable ["ACME_vent_lvlWin", _made];
