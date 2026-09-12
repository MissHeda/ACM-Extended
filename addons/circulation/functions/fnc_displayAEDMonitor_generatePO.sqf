// a CfgFunctions override of acm_circulation_fnc_displayaedmonitor_generatepo, the pulse-ox.
// it replicates the logic of ACM de-macroed, and for our custom rhythm codes, 100 and above, we render a normal
// pulsatile pleth, treating it as sinus, since a perfusing custom rhythm still produces a pulse.
// _this is [_rhythm, _spacing, _arrayOffset, _saturation].
params ["_rhythm", "_spacing", "_arrayOffset", "_saturation"];

if (_rhythm >= 100) then { _rhythm = 0; };  // custom perfusing rhythm -> sinus pleth

if (_spacing != -1) then { _arrayOffset = _arrayOffset + floor(_spacing / 2); };

// the -1 sentinel has now been consumed above. past this point a negative or non-finite spacing, which the monitor
// can hand us at a high hr or during a rhythm transition, would crash the step-array resize on the line below and
// the 176 over (15 plus spacing) repeat division with a zero divisor. clamp it to a safe non-negative integer. it
// is the same guard fn_genEKG already applies.
if (!(_spacing isEqualType 0) || {!(finite _spacing)} || {_spacing < 0}) then { _spacing = 0; };

_saturation = _saturation / 99;

private _maxLength = 176;

private _fnc_generateStepSpacingArray = {
    params ["_spacing"];
    private _stepSpacingArray = [];
    if (_spacing > 4) then {
        for "_i" from 0 to (ceil(_spacing / 4)) do {
            _stepSpacingArray = _stepSpacingArray + [(random [0, 0, 2]),(random [0, 0, 2]),(random [0, 0, 2]),(random [0, 0, 2])];
        };
    } else {
        _stepSpacingArray = [(random [0, 0, 2]),(random [0, 0, 2]),(random [0, 0, 2]),(random [0, 0, 2])];
    };
    _stepSpacingArray resize _spacing;
    _stepSpacingArray
};

private _generateNoisyRhythmStep = {
    params ["_cleanRhythmStep", "_noiseRange"];
    private _noisyRhythm = [];
    { _noisyRhythm pushBack (random [(_x - _noiseRange), _x, (_x + _noiseRange)]); } forEach _cleanRhythmStep;
    _noisyRhythm
};

private _generateSafeSpacing = {
    params ["_count", ["_safe", false]];
    private _array = [];
    for "_i" from 1 to _count do { _array pushBack _safe; };
    _array
};

private _rhythmArray = [];
private _safeSpacingArray = [];

switch (_rhythm) do {
    case -5: {  // na
        private _step = [0];
        private _repeat = ceil(176 / (count _step));
        for "_i" from 0 to _repeat do { _rhythmArray = _rhythmArray + _step; };
    };
    case -1;  // CPR
    case 0: {  // sinus
        private _cleanRhythmStep = [0, -10 * _saturation, -30 * _saturation, -40 * _saturation, -45 * _saturation, -47 * _saturation, -49.2 * _saturation, -50 * _saturation, -49.2 * _saturation, -45 * _saturation, -40 * _saturation, -35 * _saturation, -33 * _saturation, -30 * _saturation, -15 * _saturation];
        private _noiseRange = 1;
        private _repeat = ceil(176 / ((count _cleanRhythmStep) + _spacing));
        if (_arrayOffset > 0) then { _repeat = _repeat + 1; };
        for "_i" from 0 to _repeat do {
            _rhythmArray = _rhythmArray + ([_spacing] call _fnc_generateStepSpacingArray) + ([_cleanRhythmStep, _noiseRange] call _generateNoisyRhythmStep);
            _safeSpacingArray = _safeSpacingArray + ([_spacing, true] call _generateSafeSpacing) + ([15] call _generateSafeSpacing);
        };
    };
    default {
        private _step = [0];
        private _noiseRange = 2;
        private _repeat = ceil(176 / (count _step));
        for "_i" from 0 to _repeat do { _rhythmArray = _rhythmArray + ([_step, _noiseRange] call _generateNoisyRhythmStep); };
    };
};

if (_arrayOffset > 0) then { _rhythmArray deleteRange [0, _arrayOffset]; };
if (count _safeSpacingArray < 1) then { _safeSpacingArray resize [_maxLength, true]; };
_rhythmArray resize [_maxLength, 0];

[_rhythmArray, _safeSpacingArray]
