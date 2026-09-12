// how the palpating finger reports what is under it.
// call it as [_dist, _feelR, _hitR, _maxHot, _quality, _patient] call ACME_fnc_ivPalpModel, which returns
// [_color, _sizeMult, _onVein].
//
// the old behavior was one linear color ramp from red to yellow to green across the whole feel radius, and a
// fixed-size dot. That reads as a proximity meter rather than as a fingertip: the whole warm zone feels the
// same, and there is no reason to explore because nothing about the dot tells you WHAT you are on.
//
// ACME_iv_palpModel switches between the models below so they can be compared in game. 0 is the old behavior,
// kept as the baseline to judge the others against rather than as a fallback.
//
// what a control can actually express here is color, alpha and size, three channels. every model below is
// built from those three and nothing else, because a picture control has nothing else to give.
params [["_dist", 1e9], ["_feelR", 0.008], ["_hitR", 0.004], ["_maxHot", 1], ["_q", 1], ["_patient", objNull]];

private _mode = missionNamespace getVariable ["ACME_iv_palpModel", 1];
if (!(_mode isEqualType 0)) then { _mode = 1 };

private _stickable = (_dist <= _hitR) && {_maxHot >= 0.5};
private _onVein = _dist <= _feelR;

// 0, CLASSIC. exactly what shipped before this: a linear ramp across the whole feel radius and a constant dot.
if (_mode isEqualTo 0) exitWith {
    private _c = ["danger", 0.35] call ACME_fnc_a11yColor;
    if (_onVein) then {
        if (_stickable) then {
            _c = ["success", 0.95] call ACME_fnc_a11yColor;
        } else {
            private _t = (_feelR - _dist) / ((_feelR - _hitR) max 1e-6);
            (["danger", 0.55 + (0.40 * _t)] call ACME_fnc_a11yColor) params ["_cr", "_cg", "_cb", "_ca"];
            (["warning", 0.55 + (0.40 * _t)] call ACME_fnc_a11yColor) params ["_wr", "_wg", "_wb", "_wa"];
            _c = [_cr + ((_wr - _cr) * _t), _cg + ((_wg - _cg) * _t), _cb + ((_wb - _cb) * _t), _ca];
        };
    };
    [_c, 1, _onVein]
};

// how far into the warm zone we are, 0 at the outer edge and 1 at the green core.
private _t = 0;
if (_onVein) then { _t = ((_feelR - _dist) / ((_feelR - _hitR) max 1e-6)) max 0 min 1; };

// 1, RIDGE. the default, and the one built for what you asked: only a SMALL core is genuinely green and
// stickable, and everything outside it tapers hard. the yellow is squared, so the outer half of the warm zone
// is barely warm at all and you have to work the last fraction to find the cord. the dot also TIGHTENS as it
// closes, from a vague pad to a fine point, which is the closest a picture control gets to the feeling of a
// fingertip narrowing onto something.
if (_mode isEqualTo 1) exitWith {
    private _c = ["danger", 0.35] call ACME_fnc_a11yColor;
    private _sz = 1.0;
    if (_onVein) then {
        private _tt = _t * _t;  // squared, so warmth arrives late rather than linearly.
        _sz = 1.0 - (0.45 * _tt);
        if (_stickable) then {
            _c = ["success", 0.95] call ACME_fnc_a11yColor;
            _sz = 0.55;
        } else {
            (["danger", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_cr", "_cg", "_cb", "_ca"];
            (["warning", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_wr", "_wg", "_wb", "_wa"];
            _c = [_cr + ((_wr - _cr) * _tt), _cg + ((_wg - _cg) * _tt), _cb + ((_wb - _cb) * _tt), _ca];
        };
    };
    [_c, _sz, _onVein]
};

// 2, PULSE. the dot breathes at the casualty's own heart rate while it is over a vein, and the depth of the
// breath scales with how good that vein is. a fat vein throbs unmistakably, a thready one barely moves, and an
// arrested casualty does not pulse at all. this is the model that comes closest to actually feeling something
// rather than reading a meter, and it carries real information: a vein you cannot feel pulsing under your
// finger is a vein that is not going to give you a flashback.
if (_mode isEqualTo 2) exitWith {
    private _c = ["danger", 0.35] call ACME_fnc_a11yColor;
    private _sz = 1.0;
    if (_onVein) then {
        private _hr = 0;
        if (!isNull _patient) then { _hr = _patient getVariable ["ace_medical_heartRate", 80]; };
        if (!(_hr isEqualType 0) || {!finite _hr}) then { _hr = 80 };
        // amplitude falls away with distance and with a poor vein, so the throb is only clear on the cord.
        private _amp = 0.28 * _t * _t * ((_q max 0) min 1.2);
        private _beat = 0;
        if (_hr > 20) then { _beat = sin ((diag_tickTime * (_hr * 6)) mod 360); };
        _sz = (1.0 - (0.35 * _t * _t)) * (1 + (_amp * _beat));
        if (_stickable) then {
            _c = ["success", 0.95] call ACME_fnc_a11yColor;
        } else {
            private _tt = _t * _t;
            (["danger", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_cr", "_cg", "_cb", "_ca"];
            (["warning", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_wr", "_wg", "_wb", "_wa"];
            _c = [_cr + ((_wr - _cr) * _tt), _cg + ((_wg - _cg) * _tt), _cb + ((_wb - _cb) * _tt), _ca];
        };
    };
    [_c, (_sz max 0.3) min 2, _onVein]
};

// 3, EDGE. the dot brightens sharply at the WALLS of the vein and dips slightly dead center, so rolling across
// a vessel gives two distinct edges with a softer middle between them, the way a cord feels when you cross it
// rather than when you sit on it. the green core is unchanged, so it is no easier or harder to stick; it only
// changes what the approach tells you.
if (_mode isEqualTo 3) exitWith {
    private _c = ["danger", 0.35] call ACME_fnc_a11yColor;
    private _sz = 1.0;
    if (_onVein) then {
        // a ridge that peaks partway in rather than at the center.
        private _edge = 1 - (abs ((_t * 2) - 1.35));
        _edge = (_edge max 0) min 1;
        private _tt = (_t * _t * 0.55) + (_edge * 0.45);
        _sz = 1.0 - (0.40 * _edge);
        if (_stickable) then {
            _c = ["success", 0.95] call ACME_fnc_a11yColor;
            _sz = 0.60;
        } else {
            (["danger", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_cr", "_cg", "_cb", "_ca"];
            (["warning", 0.50 + (0.45 * _tt)] call ACME_fnc_a11yColor) params ["_wr", "_wg", "_wb", "_wa"];
            _c = [_cr + ((_wr - _cr) * _tt), _cg + ((_wg - _cg) * _tt), _cb + ((_wb - _cb) * _tt), _ca];
        };
    };
    [_c, _sz, _onVein]
};

// unknown mode. behave as classic rather than as nothing.
[(["danger", 0.35] call ACME_fnc_a11yColor), 1, _onVein]
