// this builds the on-screen EMMA capnograph controls, as the onload of the ACME_EMMA_Display title resource.
// everything is ctrlcreate'd here, so the positions can be computed from the safezone and tuned live.
// the frame texture is the EMMA device image, and the screen elements, the ETCO2 value, the battery, the lungs and
// /min, the rr value and the scrolling capnography waveform, are drawn over its black screen area and updated by
// fn_emmatick. the layout is tunable through the acme_emma_* globals read below.
// _this is a display.
params [["_display", displayNull]];
private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
if (_display isEqualType []) then { _display = _display param [0, displayNull]; };
if (isNull _display) exitWith {};

private _green   = ["capno", 1] call ACME_fnc_a11yColor;
private _frameTx = missionNamespace getVariable ["ACME_emma_frameTexture", "\acm_extended\ui\emma\emma_etco2_ca.paa"];
private _lungsTx = missionNamespace getVariable ["ACME_emma_lungsTexture", "\acm_extended\ui\emma\emma_lungs_ca.paa"];
private _waveCols = missionNamespace getVariable ["ACME_emma_waveCols", 64];

// the device frame rect: the left edge, vertically centerd. the device image is square, 512 by 512, so size it off
// a pixel count and use pixelw and pixelh. that keeps it a true square on any aspect. the previous aspect-divide
// math over-narrowed it, which was the smushed look.
private _szpx = missionNamespace getVariable ["ACME_emma_sizePx", 470];  // the device size, in screen px.
private _h = _szpx * pixelH;
private _w = _szpx * pixelW;
private _x = _uiX + _uiW * (missionNamespace getVariable ["ACME_emma_marginX", 0.012]);
private _y = safeZoneY + (safeZoneH - _h) * (missionNamespace getVariable ["ACME_emma_anchorY", 0.5]);

// the frame.
private _frame = _display ctrlCreate ["RscPicture", 71501];
_frame ctrlSetText _frameTx;
_frame ctrlSetPosition [_x, _y, _w, _h];
_frame ctrlCommit 0;

// the black oled screen sub-rect inside the frame, measured from the device texture and tunable so it can be nudged
// to your exact .paa. all the on-screen elements below are placed within it.
private _scx = _x + _w * (missionNamespace getVariable ["ACME_emma_screenX", 0.410]);
private _scy = _y + _h * (missionNamespace getVariable ["ACME_emma_screenY", 0.318]);
private _scw = _w * (missionNamespace getVariable ["ACME_emma_screenW", 0.291]);
private _sch = _h * (missionNamespace getVariable ["ACME_emma_screenH", 0.309]);

// the "ETCO2" label, larger, with a smaller "mmHg" beside it.
private _lbl = _display ctrlCreate ["RscText", 71502];
_lbl ctrlSetPosition [_scx + _scw * 0.04, _scy + _sch * 0.02, _scw * 0.48, _sch * 0.15];
_lbl ctrlSetText "ETCO2";
_lbl ctrlSetTextColor _green;
_lbl ctrlSetFontHeight (_sch * 0.135);
_lbl ctrlCommit 0;
private _unit = _display ctrlCreate ["RscText", 71510];
_unit ctrlSetPosition [_scx + _scw * 0.40, _scy + _sch * 0.055, _scw * 0.40, _sch * 0.11];
_unit ctrlSetText "mmHg";
_unit ctrlSetTextColor _green;
_unit ctrlSetFontHeight (_sch * 0.092);
_unit ctrlCommit 0;

// the big ETCO2 value, updated by the tick. it is the dominant element, and the font and position are tunable.
private _valFont = missionNamespace getVariable ["ACME_emma_valFont", 0.53];
private _valY    = missionNamespace getVariable ["ACME_emma_valY", 0.15];
private _val = _display ctrlCreate ["RscText", 71503];
_val ctrlSetPosition [_scx + _scw * 0.02, _scy + _sch * _valY, _scw * 0.56, _sch * _valFont];
_val ctrlSetText "--";
_val ctrlSetTextColor _green;
_val ctrlSetFontHeight (_sch * _valFont);
_val ctrlCommit 0;

// the static battery, at the top-right of the screen. the terminal nub is on the left, it reads about 85 percent
// charge, and it is small.
private _bw = _scw * 0.14; private _bh = _sch * 0.075;
private _bx = _scx + _scw * 0.81; private _by = _scy + _sch * 0.05;
private _bat = _display ctrlCreate ["RscPicture", 71504];
_bat ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
_bat ctrlSetTextColor _green;
_bat ctrlSetPosition [_bx, _by, _bw, _bh];
_bat ctrlCommit 0;
private _batTip = _display ctrlCreate ["RscPicture", 71506];  // the terminal nub, on the left.
_batTip ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
_batTip ctrlSetTextColor _green;
_batTip ctrlSetPosition [_bx - _bw * 0.10, _by + _bh * 0.28, _bw * 0.10, _bh * 0.44];
_batTip ctrlCommit 0;
private _batInner = _display ctrlCreate ["RscPicture", 71505];  // the dark, empty inset on the left.
_batInner ctrlSetText "#(argb,8,8,3)color(0,0,0,1)";
_batInner ctrlSetTextColor ([[0,0,0,1]] call ACME_fnc_cbColor);
_batInner ctrlSetPosition [_bx + _bw * 0.06, _by + _bh * 0.18, _bw * 0.16, _bh * 0.64];
_batInner ctrlCommit 0;

// the lungs glyph, whose texture the user supplied and which is tunable, plus "/min" sitting at the lower-right of
// the lungs, with its bottom no lower than the bottom of the lungs, as on the real device.
private _lung = _display ctrlCreate ["RscPicture", 71507];
_lung ctrlSetText _lungsTx;
_lung ctrlSetTextColor _green;
_lung ctrlSetPosition [_scx + _scw * 0.58, _scy + _sch * 0.16, _scw * 0.13, _sch * 0.16];
_lung ctrlCommit 0;
private _min = _display ctrlCreate ["RscText", 71508];
_min ctrlSetPosition [_scx + _scw * 0.71, _scy + _sch * 0.20, _scw * 0.29, _sch * 0.12];
_min ctrlSetText "/min";
_min ctrlSetTextColor _green;
_min ctrlSetFontHeight (_sch * 0.10);
_min ctrlCommit 0;

// the rr value, updated by the tick. it is bigger, with the baseline kept flush with the ETCO2 number, because rry
// defaults to valy plus valfont minus rrfont, so the bottoms of the two controls line up.
private _rrFont = missionNamespace getVariable ["ACME_emma_rrFont", 0.33];
private _rrY    = missionNamespace getVariable ["ACME_emma_rrY", (_valY + _valFont - _rrFont)];
private _rr = _display ctrlCreate ["RscText", 71509];
_rr ctrlSetPosition [_scx + _scw * 0.58, _scy + _sch * _rrY, _scw * 0.42, _sch * _rrFont];
_rr ctrlSetText "--";
_rr ctrlSetTextColor _green;
_rr ctrlSetFontHeight (_sch * _rrFont);
_rr ctrlCommit 0;

// the capnography waveform: a row of filled green columns across the lower screen, shaped and swept by
// fn_emmatick. the strip is slightly shorter than before, and the tick keeps a baseline sliver so it never goes
// fully blank.
private _wx = _scx + _scw * 0.04; private _wy = _scy + _sch * (missionNamespace getVariable ["ACME_emma_waveY", 0.68]);
private _ww = _scw * 0.92; private _wh = _sch * (missionNamespace getVariable ["ACME_emma_waveH", 0.26]);
private _colW = _ww / _waveCols;
for "_i" from 0 to (_waveCols - 1) do {
    private _b = _display ctrlCreate ["RscPicture", 71600 + _i];
    _b ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
    _b ctrlSetTextColor _green;
    _b ctrlSetPosition [_wx + _i * _colW, _wy + _wh, _colW * 0.92, 0];  // start flat at the baseline.
    _b ctrlCommit 0;
};

// the AED-style sweeper: a thick black bar, matching the oled background so it reads as the trace erase-edge like
// the AED. fn_emmatick repositions and widths it each frame, and it renders on top of the column bars, because it
// is created last, covering the columns it passes.
private _sw = _display ctrlCreate ["RscPicture", 71599];
_sw ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
_sw ctrlSetTextColor (missionNamespace getVariable ["ACME_emma_sweepColor", [0, 0, 0, 1]]);
_sw ctrlSetPosition [_wx, _wy, _colW * 1.7, _wh];
_sw ctrlCommit 0;

// stash the geometry the tick needs. the trace buffer is preserved across HUD rebuilds, because it is only seeded
// once, so brief show and hide cycles do not restart the sweep, and the tick re-sizes it if wavecols changes.
uiNamespace setVariable ["ACME_emma_geo", [_wx, _wy, _ww, _wh, _colW, _waveCols]];
if (isNil {uiNamespace getVariable "ACME_emma_wave"}) then { uiNamespace setVariable ["ACME_emma_wave", []]; };
if (isNil {uiNamespace getVariable "ACME_emma_lastCursor"}) then { uiNamespace setVariable ["ACME_emma_lastCursor", -1]; };
