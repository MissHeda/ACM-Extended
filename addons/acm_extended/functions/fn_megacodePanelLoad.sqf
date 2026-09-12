// the onload for the megacode control panel. it builds the live monitor and starts the per-frame tick.
// the monitor is driven by ACM's own LifePak waveform generators, the same code the in-game AED and LifePak monitor
// uses, so the traces are identical to what a medic sees on the real monitor.
// the ecg comes from ACM_circulation_fnc_displayAEDMonitor_generateEKG, on lane 0, green, paired with hr.
// the pleth comes from acm_circulation_fnc_displayaedmonitor_generatepo, on lane 1, cyan, paired with SpO2.
// the ABP is a synthesized arterial waveform, because ACM has no ABP generator, on lane 2, red, paired with NIBP.
// the capno comes from acm_circulation_fnc_displayaedmonitor_generateco, on lane 3, yellow, paired with EtCO2.
// capnography is the respiratory waveform, so rr and temp are shown as numbers only, with no lane.
// each lane is a row of thin bar controls forming a connected trace. a sweep cursor advances across the columns
// each tick, copying the freshly generated waveform in and blanking a small gap at the cursor. that is exactly the
// refresh-sweep the ACM monitor uses, and it is far cheaper than repositioning every bar every frame.
params ["_display"];
uiNamespace setVariable ["ACME_Megacode_DLG", _display];

private _dummy = uiNamespace getVariable ["ACME_MC_target", objNull];
// seed the panel-authoritative vitals on the dummy. it is a deterministic testing tool, so what you set is what
// shows and runs.
if (!isNull _dummy) then {
    {
        _x params ["_v", "_d"];
        if (isNil {_dummy getVariable _v}) then { _dummy setVariable [_v, _d, true]; };
    } forEach [
        ["ACME_MC_HR", 78], ["ACME_MC_SpO2", 98], ["ACME_MC_SBP", 122], ["ACME_MC_DBP", 78],
        ["ACME_MC_RR", 14], ["ACME_MC_EtCO2", 38], ["ACME_MC_Temp", 37.0]
    ];
};

private _X = safeZoneX; private _Y = safeZoneY; private _W = safeZoneW; private _H = safeZoneH;
// a fixed-aspect panel: the width equals the original 16:9 width, centerd horizontally, so the layout keeps its
// shape on 16:9, 21:9 and 32:9 instead of stretching with safeZoneW. 1.61 is the old 16:9 _pW over _pH ratio.
private _pW = _H * 0.85 * 1.61;
private _pX = _X + (_W - _pW) / 2;
private _pY = _Y + _H * 0.075;
private _pH = _H * 0.85;

private _waveLeft = _pX + 0.040;
private _waveW    = _pW * 0.600;
private _waveTop  = _pY + _H * 0.050;
private _laneBlock = _pH * 0.42;  // the lanes occupy the top 0.42 or so of the panel, so the readouts clear the tab bar.
private _laneH    = _laneBlock / 4;

// [label, color, scale, kind], where the scale is px into lane. the lanes are ordered to line up with the readouts
// on the right.
private _lanes = [
    ["II",    (["success", 1] call ACME_fnc_a11yColor), 55,  "ekg"],
    ["Pleth", (["cyan", 1] call ACME_fnc_a11yColor), 55,  "pleth"],
    ["ABP",   [1.00, 0.32, 0.32, 1], 100, "abp"],
    ["CO2",   [1.00, 0.95, 0.45, 1], 135, "capno"]
];

private _N = round ((missionNamespace getVariable ["ACME_megacode_waveCols", 400]) max 60);  // more, thinner columns give a smoother trace.
private _colW = _waveW / _N;
uiNamespace setVariable ["ACME_MC_colSecs", (missionNamespace getVariable ["ACME_megacode_waveColSecs", 0.024])];  // the sweep and regen time-base, read by the tick.
private _barCtrls = [];  // [[lane0 ctrls...], ...].
private _laneGeo  = [];  // [cy, halfh, scale, kind] per lane.
private _laneCy   = [];  // cy per lane, for aligning the readouts.

{
    _x params ["_lbl", "_col", "_scale", "_kind"];
    private _laneTop = _waveTop + (_laneH * _forEachIndex);
    private _cy = _laneTop + (_laneH * 0.5);
    private _halfH = _laneH * 0.42;
    _laneGeo pushBack [_cy, _halfH, _scale, _kind];
    _laneCy pushBack _cy;

    private _t = _display ctrlCreate ["RscText", -1];
    _t ctrlSetPosition [_pX - 0.002, _laneTop + 0.002, 0.045, 0.03];
    _t ctrlSetText _lbl; _t ctrlSetTextColor _col; _t ctrlCommit 0;

    private _laneCtrls = [];
    for "_i" from 0 to (_N - 1) do {
        private _c = _display ctrlCreate ["RscText", -1];
        _c ctrlSetBackgroundColor _col;
        _c ctrlSetPosition [_waveLeft + (_i * _colW), _cy, _colW + 0.0007, 0.0018];
        _c ctrlCommit 0;
        _laneCtrls pushBack _c;
    };
    _barCtrls pushBack _laneCtrls;
} forEach _lanes;

uiNamespace setVariable ["ACME_MC_bars", _barCtrls];
uiNamespace setVariable ["ACME_MC_laneGeo", _laneGeo];
uiNamespace setVariable ["ACME_MC_N", _N];
uiNamespace setVariable ["ACME_MC_waveGeo", [_waveLeft, _colW]];
// the display, meaning currently shown, and refresh, meaning target waveform, sample arrays per lane. both are
// flat to start.
private _flat = []; _flat resize _N; _flat = _flat apply { 0 };
uiNamespace setVariable ["ACME_MC_disp", [+_flat, +_flat, +_flat, +_flat]];
uiNamespace setVariable ["ACME_MC_refresh", [+_flat, +_flat, +_flat, +_flat]];
uiNamespace setVariable ["ACME_MC_cursor", 0];
uiNamespace setVariable ["ACME_MC_colAcc", 0];
uiNamespace setVariable ["ACME_MC_phase", 0];
uiNamespace setVariable ["ACME_MC_lastT", diag_tickTime];
uiNamespace setVariable ["ACME_MC_sig", ""];
uiNamespace setVariable ["ACME_MC_regenAt", 0];
// the new sweep state: the source waveform and its age, where 1e6 forces a regen, plus the first-paint latch.
uiNamespace setVariable ["ACME_MC_src", []];
uiNamespace setVariable ["ACME_MC_srcAge", 1e6];
uiNamespace setVariable ["ACME_MC_filled", false];

// the readouts: the four waveform vitals on the right, each vertically centerd on its lane row.
private _vX = _pX + (_pW * 0.66);
private _vW = _pW * 0.33;
// [key, label, color, unit, laneindex].
private _vits = [
    ["HR",   "HR",    (["success", 1] call ACME_fnc_a11yColor), "bpm",  0],
    ["SpO2", "SpO2",  (["cyan", 1] call ACME_fnc_a11yColor), "%",    1],
    ["BP",   "NIBP",  [1.00, 0.45, 0.45, 1], "mmHg", 2],
    ["EtCO2","EtCO2", [1.00, 0.95, 0.45, 1], "mmHg", 3]
];
private _vCtrls = createHashMap;
{
    _x params ["_key", "_lbl", "_col", "_unit", "_li"];
    private _cy = _laneCy select _li;
    private _lblC = _display ctrlCreate ["RscText", -1];
    _lblC ctrlSetPosition [_vX, _cy - (_laneH * 0.42), _vW, _laneH * 0.30];
    _lblC ctrlSetText (format ["%1 (%2)", _lbl, _unit]);
    _lblC ctrlSetTextColor _col; _lblC ctrlCommit 0;
    private _numC = _display ctrlCreate ["RscStructuredText", -1];
    _numC ctrlSetPosition [_vX, _cy - (_laneH * 0.12), _vW, _laneH * 0.56];
    // size the number to its box. NIBP holds the longer "120/80", so it is a touch smaller.
    _numC ctrlSetFontHeight (_laneH * (if (_key isEqualTo "BP") then { 0.40 } else { 0.46 }));
    _numC ctrlCommit 0;
    _vCtrls set [_key, [_numC, _col]];
} forEach _vits;

// rr and temp as smaller secondary numbers under the lanes, because capnography already shows the
// respirations.
private _secTop = _waveTop + _laneBlock + (_H * 0.012);
{
    _x params ["_key", "_lbl", "_col", "_unit", "_ix"];
    private _sx = _vX + (_ix * (_vW * 0.5));
    private _lblC = _display ctrlCreate ["RscText", -1];
    _lblC ctrlSetPosition [_sx, _secTop, _vW * 0.5, _laneH * 0.26];
    _lblC ctrlSetText (format ["%1 (%2)", _lbl, _unit]);
    _lblC ctrlSetTextColor _col; _lblC ctrlCommit 0;
    private _numC = _display ctrlCreate ["RscStructuredText", -1];
    _numC ctrlSetPosition [_sx, _secTop + (_laneH * 0.22), _vW * 0.5, _laneH * 0.40];
    _numC ctrlSetFontHeight (_laneH * 0.30);
    _numC ctrlCommit 0;
    _vCtrls set [_key, [_numC, _col]];
} forEach [
    ["RR",   "RR",   [1.00, 1.00, 1.00, 1], "/min", 0],
    ["Temp", "Temp", [1.00, 0.70, 0.30, 1], "C",    1]
];
uiNamespace setVariable ["ACME_MC_vitalCtrls", _vCtrls];

// the live tick.
private _pfh = [{ call ACME_fnc_megacodePanelTick }, 0.03, []] call CBA_fnc_addPerFrameHandler;
uiNamespace setVariable ["ACME_MC_tickPFH", _pfh];

// the default page.
uiNamespace setVariable ["ACME_MC_page", "vitals"];
[87300, "vitals"] call ACME_fnc_megacodeMenu;
