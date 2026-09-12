// the alarm window. press the bell and the machine tells you, on its own screen, exactly what is wrong.
// [] call ACME_fnc_ventAlarmWindow toggles it open and closed.
// [true] call ACME_fnc_ventAlarmWindow pages to the next alarm.
// ["repaint"] call ACME_fnc_ventAlarmWindow redraws the current page and selection, which the dial and activate
// use.
// it is modeled on the real sparrow: a bordered panel over the screen, the severity word on white, the alarm
// text large on a colored field, a cyan x, and a next arrow at the bottom when there is more than one alarm.
// it is dial driven, like every other screen on this panel. there is no mouse on this device, so the knob moves
// the selection between the bottom buttons and a middle-click activates the one under the cursor. that is the
// fix for not being able to press the x or cycle the alarms. the window used to rely on RscButton mouse clicks,
// which never fire in a scroll-and-select ui, so it was a wall you could look at and not touch.
// color is the message. red means the patient is not being ventilated or is being injured right now. yellow
// means ventilation is going wrong and not instantly fatally. gray is informational.
params [["_mode", false]];
disableSerialization;

private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

private _tgt = uiNamespace getVariable ["ACME_vent_target", objNull];
private _alarms = if (isNull _tgt) then {[]} else {_tgt getVariable ["ACME_vent_alarms", []]};

private _old = uiNamespace getVariable ["ACME_vent_alarmWin", []];
private _wasOpen = (count _old) > 0;

{ if (!isNull _x) then { ctrlDelete _x; }; } forEach _old;
uiNamespace setVariable ["ACME_vent_alarmWin", []];

// _mode is false to toggle, from the bell, true to page to the next alarm, and "repaint" to redraw in place, for
// the dial and activate.
private _isRepaint = (_mode isEqualType "") && {_mode == "repaint"};
private _isNext    = (_mode isEqualType true) && {_mode};

// toggle shut on a second bell press, and mark the window closed so the dial goes back to the live screen.
if (_wasOpen && {!_isNext} && {!_isRepaint}) exitWith {
    uiNamespace setVariable ["ACME_vent_alarmPage", 0];
    uiNamespace setVariable ["ACME_vent_alarmWinOpen", false];
};
if (_alarms isEqualTo []) exitWith {
    uiNamespace setVariable ["ACME_vent_alarmPage", 0];
    uiNamespace setVariable ["ACME_vent_alarmWinOpen", false];
    ["No active alarms.", 1.5] call ace_common_fnc_displayTextStructured;
};

private _page = uiNamespace getVariable ["ACME_vent_alarmPage", 0];
if (_isNext) then { _page = _page + 1; };
if (_page >= (count _alarms)) then { _page = 0; };
uiNamespace setVariable ["ACME_vent_alarmPage", _page];
uiNamespace setVariable ["ACME_vent_alarmWinOpen", true];

// the selection over the bottom buttons: 0 is x, which silences, and 1 is next, only when there is more than one
// alarm. it resets to x on the first open.
private _multi = (count _alarms) > 1;
private _sel = uiNamespace getVariable ["ACME_vent_alarmSel", 0];
if (!_wasOpen) then { _sel = 0; };
if (!_multi) then { _sel = 0; };
uiNamespace setVariable ["ACME_vent_alarmSel", _sel];

private _name = _alarms select _page;
private _sev  = [_name] call ACME_fnc_ventAlarmSeverity;

// the palette and the flash come straight from the device manual. only the HIGH tier is red, and LOW and medium
// are both yellow and separated by their flash rate rather than by color.
// LOW is yellow and constant on, at a duty cycle of 100 percent.
// medium is yellow, flashing at 0.45 hz, at a duty cycle of 50 percent.
// HIGH is red, flashing at 2 hz, at a duty cycle of 50 percent.
// LOW used to be gray, which is not a color this device uses for an alarm at all.
// it is resolved once here and published, so the flash driver in fn_ventpaneltick reuses the corrected color
// rather than re-deriving it. protect matters more here than anywhere else in the addon, because this is the
// alarm fill and a correction that dimmed it toward the panel background would be actively dangerous.
// red against yellow is the worst pair in the addon for red-green deficiency and the one that must never
  // HIGH is red.
  // medium and LOW are yellow.
// tritanopia from 0.510 to 0.562.
private _fill = switch (_sev) do {
    case 3: { [[0.86, 0.08, 0.08, 1]] call ACME_fnc_ventColor };  // HIGH   red
    default { [[0.93, 0.78, 0.10, 1]] call ACME_fnc_ventColor };  // medium and LOW   yellow
};
// yellow needs dark text, and red carries white.
private _ink = if (_sev == 3) then {[1,1,1,1]} else {[0.05,0.05,0.05,1]};

// published for the panel tick, which does the actual flashing. an hz of 0 means constant.
uiNamespace setVariable ["ACME_vent_alarmFlashHz", (switch (_sev) do { case 3: {2}; case 2: {0.45}; default {0} })];
uiNamespace setVariable ["ACME_vent_alarmFillCol", _fill];

(uiNamespace getVariable ["ACME_vent_scrRect", [0,0,1,1]]) params ["_sx","_sy","_sw","_sh"];
private _ctrls = [];
private _mk = {
    params ["_cls","_x","_y","_w","_h"];
    private _c = _dlg ctrlCreate [_cls, -1];
    _c ctrlSetPosition [_sx + _sw*_x, _sy + _sh*_y, _sw*_w, _sh*_h];
    _c ctrlSetBackgroundColor ([[0,0,0,0]] call ACME_fnc_ventColor);
    _c ctrlCommit 0; _c ctrlShow true;
    _ctrls pushBack _c;
    _c
};

// a white frame fitted between the bars. the border is the window on this device.
private _fr = ["RscText", 0.03, 0.150, 0.94, 0.705] call _mk;
_fr ctrlSetBackgroundColor ([[1, 1, 1, 1]] call ACME_fnc_ventColor);

// the title: the tier word, in the same font and size as every other title on the device, in black, on the top
// left.
// it is a plain RscText rather than structured text, so it takes ctrlSetFontHeight directly and therefore reads
// at exactly the height the list titles use, ACME_vent_titleHeightFrac. structured text sized it by a
// multiplier, which is how it kept coming out larger than everything else and colliding with the colored
// field.
// it is black rather than the alarm color. the color already says how urgent this is, twice: the field below is
// filled with it and it flashes at the rate of the tier. repeating it in the title just made the word hard to
// read on white.
private _hd = ["RscText", 0.055, 0.152, 0.89, 0.075] call _mk;
_hd ctrlSetText (switch (_sev) do { case 3: {"ALARM"}; case 2: {"WARNING"}; default {"ALERT"} });
_hd ctrlSetFontHeight (_sh * (missionNamespace getVariable ["ACME_vent_titleHeightFrac", 0.125]));
_hd ctrlSetTextColor ([[0.05, 0.05, 0.05, 1]] call ACME_fnc_ventColor);
_hd ctrlSetBackgroundColor ([[0,0,0,0]] call ACME_fnc_ventColor);

// the colored field carrying the alarm text, which is the thing you read from across the cabin. it ends above
// the button row, which sits at 0.752, so the text can never spill onto the buttons.
private _bd = ["RscText", 0.055, 0.255, 0.89, 0.465] call _mk;
_bd ctrlSetBackgroundColor _fill;
uiNamespace setVariable ["ACME_vent_alarmFillCtrl", _bd];

// the alarm text. it is rendered as one RscText control per line, each with an absolute font height, an
// sh-fraction, so the sizing is deterministic. the old version used a single RscStructuredText whose size
// attribute is a multiplier of an unknown base font, which is why long names overran and clipped to just the
// first word, showing "HIGH" instead of "HIGH MINUTE VOLUME". the name is split into balanced whole-word lines,
  // break to a new line past about 10 characters, so long names split instead of running off.
// critical alarms shout. a high-tier alarm is the machine telling you somebody is in trouble right now, and the
// device prints those with three exclamation marks. they are appended for display only, so _name is still the
// plain alarm string everywhere else, because the letter code, the logbook and the alarm list all match on it,
// and nothing downstream has to know about the decoration.
private _disp = if (_sev >= 3) then { _name + "!!!" } else { _name };
private _words = _disp splitString " ";
private _target = 10;  // break to a new line past ~10 chars, so long names split instead of running off
private _lines = [];
private _cur = "";
{
    private _try = if (_cur == "") then {_x} else {_cur + " " + _x};
    if ((count _try) > _target && {_cur != ""}) then {
        _lines pushBack _cur; _cur = _x;
    } else {
        _cur = _try;
    };
} forEach _words;
if (_cur != "") then { _lines pushBack _cur; };
private _nLines = count _lines;

// the field the text lives in, inside the colored body: x 0.075 to 0.925, which is 0.85 sw, and y 0.255 to
// 0.720, which is 0.465 sh.
private _fldX = 0.075; private _fldW = 0.85;
private _fldY = 0.255; private _fldH = 0.465;
private _maxLineCh = 1;
{ _maxLineCh = _maxLineCh max (count _x); } forEach _lines;
// the absolute font height, an sh-fraction. width-limited, ch times 0.56 times f times sh times pxw over pxh
// equals fldw times sw, so solve for f. height-limited, nlines times f times 1.2 must be at or below fldh. take
// the smaller, and cap it so a one-word alarm is not comically huge.
private _fW = (_fldW * _sw) / (_maxLineCh * 0.56 * _sh * (pixelW / pixelH));
private _fH = _fldH / (_nLines * 1.2);
private _fLine = (_fW min _fH) min 0.16;

// vertically center the block of lines within the field.
private _lineStep = _fLine * 1.2;
private _blockH = _nLines * _lineStep;
private _y0 = _fldY + (_fldH - _blockH) / 2;

{
    private _ln = _dlg ctrlCreate ["ACME_VentTextC", -1];
    _ln ctrlSetPosition [_sx + _sw*_fldX, _sy + _sh*(_y0 + _forEachIndex*_lineStep), _sw*_fldW, _sh*_lineStep];
    _ln ctrlSetText _x;
    _ln ctrlSetFontHeight (_sh * _fLine);
    _ln ctrlSetFont "PuristaBold";
    _ln ctrlSetTextColor _ink;
    _ln ctrlSetBackgroundColor ([[0,0,0,0]] call ACME_fnc_ventColor);
    _ln ctrlCommit 0; _ln ctrlShow true;
    _ctrls pushBack _ln;
} forEach _lines;

// the bottom row, which is dial-selectable.
// the dismiss control is the silence icon, a crossed bell, matching the device, so pressing it silences, exactly
// as the reference alarm card shows a silence glyph rather than an x. the selection highlight is a cyan fill the
// dial moves, and a middle-click, through ventPanelActivateSel, fires whatever is selected.
private _hlCol = [0, 0.988, 0.992, 1];

// the paging readout, such as "(2/3)", when there is more than one, so the medic knows there is more.
if (_multi) then {
    private _pg = ["RscText", 0.055, 0.755, 0.30, 0.065] call _mk;
    _pg ctrlSetText format ["(%1/%2)", _page + 1, count _alarms];
    _pg ctrlSetFontHeight (_sh * 0.055);
    _pg ctrlSetTextColor ([[0.25, 0.25, 0.25, 1]] call ACME_fnc_ventColor);  // the icon height as an sh-fraction.
};  // the matching width as an sw-fraction, so it is square in pixels.

// the silence icon: a crossed bell on cyan, the device's own silence control, alarm_silenced_ca. selected is
// solid cyan and unselected is a faint wash. it is centerd when it is the only control and left when a next
// arrow shares the row.
// the glyph is square, so its rect must be square in pixels. derive the width from the height through the pixel
// ratio, because the screen is far wider than tall, so a width in sw-fraction equal to the height in sh-fraction
// comes out badly stretched. that is why the bell looked squashed sideways.
private _silHlOn = (_sel == 0);
private _icoH = 0.078;  // icon height as sh-fraction
private _icoWsw = (_icoH * _sh) / pixelH * pixelW / _sw;  // matching width as sw-fraction (square in pixels)
private _silX = if (_multi) then {0.40} else {0.435};
private _sbg = ["RscText", _silX, 0.752, 0.145, 0.095] call _mk;
_sbg ctrlSetBackgroundColor (if (_silHlOn) then {_hlCol} else {[0.80,0.94,1,0.35]});
// center the square glyph within the 0.145-wide button cell.
private _siX = _silX + (0.145 - _icoWsw) / 2;
private _si = ["RscPicture", _siX, 0.760, _icoWsw, _icoH] call _mk;
_si ctrlSetText "\acm_extended\ui\vent\alarm_silenced_ca.paa";

// the next arrow, only when there is more than one alarm. selected is a filled cyan behind the glyph.
if (_multi) then {
    private _nHlOn = (_sel == 1);
    private _nb = ["RscText", 0.70, 0.752, 0.145, 0.095] call _mk;
    _nb ctrlSetBackgroundColor (if (_nHlOn) then {_hlCol} else {[0.80,0.94,1,0.35]});
    private _niX = 0.70 + (0.145 - _icoWsw) / 2;
    private _ni = ["RscPicture", _niX, 0.760, _icoWsw, _icoH] call _mk;
    _ni ctrlSetText "\acm_extended\ui\vent\next_screen_ca.paa";
};

uiNamespace setVariable ["ACME_vent_alarmWin", _ctrls];
