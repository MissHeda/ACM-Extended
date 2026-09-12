// the per-frame megacode monitor update, a LifePak-15-style sweep. a cursor advances left to right at the real
// monitor time-base, ACME_megacode_waveColSecs per column, and overwrites the previous trace with the live
// waveform as it passes, leaving a short blanking gap just ahead of the cursor, the erase bar. the waveforms come
// from ACM's own LifePak generators, and they are time-anchored, so the beats land at their true instants and the
// on-screen rate matches the BPM.
// it is robust to a missing target, because it falls back to default vitals so the monitor is never blank.
private _disp = uiNamespace getVariable ["ACME_Megacode_DLG", displayNull];
if (isNull _disp) exitWith {};
private _dummy = uiNamespace getVariable ["ACME_MC_target", objNull];  // it may be null, so the defaults below apply.

private _HR    = _dummy getVariable ["ACME_MC_HR", 78];
private _SpO2  = _dummy getVariable ["ACME_MC_SpO2", 98];
private _SBP   = _dummy getVariable ["ACME_MC_SBP", 122];
private _DBP   = _dummy getVariable ["ACME_MC_DBP", 78];
private _RR    = _dummy getVariable ["ACME_MC_RR", 14];
private _EtCO2 = _dummy getVariable ["ACME_MC_EtCO2", 38];
private _Temp  = _dummy getVariable ["ACME_MC_Temp", 37.0];
private _acmRhythm = _dummy getVariable ["ACM_circulation_Cardiac_RhythmState", 0];
private _pulseless = _acmRhythm in [1, 2, 3, 5];
if (_acmRhythm == 5) then {_SBP = 0; _DBP = 0;};

private _N      = uiNamespace getVariable ["ACME_MC_N", 176];
private _dtCol  = uiNamespace getVariable ["ACME_MC_colSecs", 0.024];  // seconds per column, which is the sweep and the sample spacing.
private _bars   = uiNamespace getVariable ["ACME_MC_bars", []];
private _geo    = uiNamespace getVariable ["ACME_MC_laneGeo", []];
private _dispA  = uiNamespace getVariable ["ACME_MC_disp", []];
private _srcA   = uiNamespace getVariable ["ACME_MC_src", []];
private _srcAge = uiNamespace getVariable ["ACME_MC_srcAge", 1e6];
(uiNamespace getVariable ["ACME_MC_waveGeo", [0,0]]) params ["_waveLeft", "_colW"];
if (_bars isEqualTo [] || {_geo isEqualTo []}) exitWith {};

private _now = diag_tickTime;
private _lastT = uiNamespace getVariable ["ACME_MC_lastT", _now];
private _dt = (_now - _lastT) min 0.2;
uiNamespace setVariable ["ACME_MC_lastT", _now];

// generate, or regenerate, the time-anchored source waveform. it is throttled, or immediate on a vitals or rhythm
// change.
// src[lane][i] is the sample i columns, which is i times _dtCol seconds, after the regen instant, so indexing
// src[srcage] always yields the true current sample with zero drift. we regen before srcage runs off the
// array.
private _sig = format ["%1-%2-%3-%4-%5-%6-%7-%8", round _HR, round _SpO2, round _SBP, round _DBP, round _RR, round _EtCO2, _acmRhythm, _pulseless];
if (_srcA isEqualTo [] || {_srcAge >= (_N - 12)} || {_sig != (uiNamespace getVariable ["ACME_MC_sig", ""])}) then {
    uiNamespace setVariable ["ACME_MC_sig", _sig];
    // build the source as a continuous function of absolute time, giving sharp narrow complexes over a long flat
    // baseline, which is the LifePak-15 look rather than ACM's chunky 15-sample complex. it is inherently seamless
    // across regens, so no offset bookkeeping is needed. up is negative, because the screen y grows downward. the
    // lane scales are ii 55, pleth 55, ABP 100 and CO2 135. the gaussian helper g(x,c,s) is exp(-((x-c)/s)^2), and
    // sin() is in degrees.
    private _phase = uiNamespace getVariable ["ACME_MC_phase", 0];
    private _Tbeat = 60 / (_HR max 20);  // seconds per cardiac cycle.
    private _Tbreath = 60 / (_RR max 4);  // seconds per respiratory cycle.
    private _ppAmp = linearConversion [20, 80, (_SBP - _DBP), 0.45, 1.0, true];
    private _g = { params ["_x","_c","_s"]; private _z = (_x - _c) / _s; exp (-(_z * _z)) };

    private _flat = []; _flat resize _N; _flat = _flat apply { 0 };
    private _ekg = +_flat; private _pleth = +_flat; private _abp = +_flat; private _capno = +_flat;

    for "_i" from 0 to (_N - 1) do {
        private _absT = (_phase + _i) * _dtCol;
        private _tb = _absT % _Tbeat;  // seconds into the current cardiac cycle.
        private _bp = _tb / _Tbeat;  // the cardiac phase, 0 to 1.

        // the ecg, by rhythm.
        private _e = switch (true) do {
            case (_acmRhythm == 0): {  // sinus: organized p-QRS-t with a sharp narrow QRS.
                  (-10 * ([_tb, 0.160, 0.025] call _g))
                + (  7 * ([_tb, 0.235, 0.012] call _g))
                + (-50 * ([_tb, 0.262, 0.020] call _g))
                + ( 16 * ([_tb, 0.290, 0.013] call _g))
                + (-17 * ([_tb, 0.430, 0.050] call _g))
            };
            case (_acmRhythm == 5): {  // PEA: slow broad abnormal organized complexes, electrical only.
                  (-48 * ([_tb, 0.255, 0.055] call _g))
                + ( 27 * ([_tb, 0.365, 0.050] call _g))
                + ( -5 * ([_tb, 0.465, 0.085] call _g))
            };
            case (_acmRhythm == 4):  { -34 * sin (360 * _bp) };  // vt: wide and regular.
            case (_acmRhythm == 3):  { (-32 * sin (360 * _bp)) * (0.55 + 0.45 * sin (360 * (_absT / (_Tbeat * 6)))) };  // PVT and torsades.
            case (_acmRhythm == 2):  { -(22 * sin (360 * (_absT / 0.17)) + 15 * sin (360 * (_absT / 0.10) + 75) + 10 * sin (360 * (_absT / 0.26) + 130)) };  // vf.
            case (_acmRhythm == 1):  { -2 * sin (360 * (_absT / 0.7)) };  // asystole: near-flat.
            case (_acmRhythm == -1): { -40 * sin (180 * ((_absT % 0.545) / 0.545)) };  // CPR at about 110 a minute.
            default { 0 };
        };
        private _motion = [_dummy] call ACME_fnc_ecgArtifactStrength;
        if (_motion > 0) then {
            _e = _e + ((sin (360 * (_absT / 0.19))) * 2.2 * _motion) + ((sin (360 * (_absT / 0.073))) * 1.2 * _motion);
            if (((floor (_absT * 7)) mod 13) == 0) then {_e = _e + (9 * _motion * sin (360 * (_absT / 0.035)));};
        };
        _ekg set [_i, _e];

        if (!_pulseless) then {
            // pleth: a rounded pulse with a dicrotic notch.
            private _ps = call {
                if (_bp < 0.13) exitWith { _bp / 0.13 };
                if (_bp < 0.34) exitWith { 1 - ((_bp - 0.13) / 0.21) * 0.5 };
                if (_bp < 0.42) exitWith { 0.5 - ((_bp - 0.34) / 0.08) * 0.12 };
                if (_bp < 0.50) exitWith { 0.38 + ((_bp - 0.42) / 0.08) * 0.10 };
                0.48 * (1 - ((_bp - 0.50) / 0.50))
            };
            _pleth set [_i, -(_ps * 48)];

            // ABP: a sharp upstroke, a dicrotic notch and a diastolic decay.
            private _as = call {
                if (_bp < 0.10) exitWith { _bp / 0.10 };
                if (_bp < 0.28) exitWith { 1 - ((_bp - 0.10) / 0.18) * 0.45 };
                if (_bp < 0.34) exitWith { 0.55 - ((_bp - 0.28) / 0.06) * 0.13 };
                if (_bp < 0.40) exitWith { 0.42 + ((_bp - 0.34) / 0.06) * 0.10 };
                0.52 * (1 - ((_bp - 0.40) / 0.60))
            };
            _abp set [_i, -(12 + (_as * 80 * _ppAmp))];
        };

        // capnography: a breath-driven square wave, with a sharp rise, a plateau and a sharp fall, and the plateau scaled
        // by EtCO2.
        private _rp = (_absT % _Tbreath) / _Tbreath;
        private _cs = call {
            if (_rp < 0.33) exitWith { 0 };
            if (_rp < 0.40) exitWith { (_rp - 0.33) / 0.07 };
            if (_rp < 0.90) exitWith { 0.92 + ((_rp - 0.40) / 0.50) * 0.08 };
            1 - ((_rp - 0.90) / 0.10)
        };
        _capno set [_i, -(_cs * _EtCO2 * 2.9)];
    };
    _srcA = [_ekg, _pleth, _abp, _capno];
    uiNamespace setVariable ["ACME_MC_src", _srcA];
    _srcAge = 0;

    // the first paint after the panel opens: lay the whole trace down, so the screen is not blank for one sweep.
    if !(uiNamespace getVariable ["ACME_MC_filled", false]) then {
        {
            private _li = _forEachIndex;
            (_geo select _li) params ["_cy", "_halfH", "_scale", "_kind"];
            private _src = _srcA select _li; private _dsp = _dispA select _li; private _lc = _bars select _li;
            for "_i" from 0 to (_N - 1) do {
                _dsp set [_i, _src select _i];
                private _v0 = _src select _i; private _v1 = _src select ((_i + 1) % _N);
                private _y0 = _cy + (((_v0 / _scale) max -1 min 1) * _halfH);
                private _y1 = _cy + (((_v1 / _scale) max -1 min 1) * _halfH);
                private _c = _lc select _i;
                _c ctrlSetPosition [_waveLeft + (_i * _colW), (_y0 min _y1), _colW + 0.0007, ((abs (_y0 - _y1)) max 0.0016)];
                _c ctrlShow true; _c ctrlCommit 0;
            };
        } forEach _bars;
        uiNamespace setVariable ["ACME_MC_filled", true];
    };
};

// advance the sweep at the tunable time-base, _dtCol seconds per column, and overwrite the swept columns.
private _cursor = uiNamespace getVariable ["ACME_MC_cursor", 0];
private _colAcc = (uiNamespace getVariable ["ACME_MC_colAcc", 0]) + (_dt / _dtCol);
private _steps = (floor _colAcc) min (_N - 1);
_colAcc = _colAcc - (floor _colAcc);
private _gap = 3;

if (_steps > 0) then {
    {
        private _li = _forEachIndex;
        (_geo select _li) params ["_cy", "_halfH", "_scale", "_kind"];
        private _src = _srcA select _li;
        private _dsp = _dispA select _li;
        private _lc  = _bars select _li;
        // paint the freshly swept columns from the live source, overwriting the trace of the last sweep.
        for "_j" from 1 to _steps do {
            private _col = (_cursor + _j) % _N;
            // connect each swept column to the next source sample, which is the true waveform continuation. the source is a
            // phase-continuous function, seamless across regens, so the source index wraps with % _n rather than clamping at
            // _n-1. clamping made the final columns of a sweep all sample the same end value, which flattened the trace at
            // the wrap seam instead of finishing the breath or beat and carrying across to column 0. wrapping closes the
            // waveform cleanly at the end of every sweep.
            private _v0 = _src select ((_srcAge + _j) % _N);
            private _v1 = _src select ((_srcAge + _j + 1) % _N);
            _dsp set [_col, _v0];
            private _y0 = _cy + (((_v0 / _scale) max -1 min 1) * _halfH);
            private _y1 = _cy + (((_v1 / _scale) max -1 min 1) * _halfH);
            private _c = _lc select _col;
            _c ctrlSetPosition [_waveLeft + (_col * _colW), (_y0 min _y1), _colW + 0.0007, ((abs (_y0 - _y1)) max 0.0016)];
            _c ctrlShow true; _c ctrlCommit 0;
        };
        // the erase bar: blank the small gap just ahead of the cursor.
        for "_g" from 1 to _gap do { (_lc select ((_cursor + _steps + _g) % _N)) ctrlShow false; };
    } forEach _bars;
    _srcAge = _srcAge + _steps;
    _cursor = (_cursor + _steps) % _N;
    // advance the cumulative sweep phase, which drives the phase-continuous regen offset above.
    uiNamespace setVariable ["ACME_MC_phase", (uiNamespace getVariable ["ACME_MC_phase", 0]) + _steps];
};

uiNamespace setVariable ["ACME_MC_cursor", _cursor];
uiNamespace setVariable ["ACME_MC_colAcc", _colAcc];
uiNamespace setVariable ["ACME_MC_srcAge", _srcAge];

// the readouts, throttled. the font height is set on the controls in panelload, so they fit their boxes.
private _vt = (uiNamespace getVariable ["ACME_MC_vitalTick", 0]) + 1;
if (_vt >= 5) then {
    _vt = 0;
    private _vC = uiNamespace getVariable ["ACME_MC_vitalCtrls", createHashMap];
    {
        _x params ["_key", "_txt", "_hex"];
        private _e = _vC getOrDefault [_key, []];
        if !(_e isEqualTo []) then {
            (_e select 0) ctrlSetStructuredText parseText format [
                "<t align='center' valign='middle' color='%1' font='PuristaBold'>%2</t>", _hex, _txt
            ];
        };
    } forEach [
        ["HR",    (if (_pulseless) then {"--"} else {str round _HR}),   "#4dff4d"],
        ["SpO2",  (if (_pulseless) then {"--"} else {str round _SpO2}), "#4df2ff"],
        ["BP",    (if (_pulseless) then {"--"} else {format ["%1/%2", round _SBP, round _DBP]}), "#ff7373"],
        ["EtCO2", str round _EtCO2,                                     "#fff073"],
        ["RR",    str round _RR,                                        "#ffffff"],
        ["Temp",  format ["%1", (round (_Temp * 10)) / 10],            "#ffb24d"]
    ];
};
uiNamespace setVariable ["ACME_MC_vitalTick", _vt];
