// a CfgFunctions override of ACM_circulation_fnc_displayAEDMonitor_generateEKG.
// ACM compiles its functions final, so a runtime reassignment cannot replace them. this compile-time override, and
// our addon loads after ACM_circulation, is the mechanism that wins.
// we replicate ACM's original waveforms verbatim and add three corrections.
// a. delegation. rhythm codes of 100 and above go to our custom generator, for AFib, SVT, torsades and the rest.
// b. the rate lock, so the waveform, the beep and the BPM agree. ACM spaces beats by a _spacing of (60/hr) times
// 15 columns of gap, then appends the complex, so one beat is _spacing plus complexlen columns. the beep, in
// fnc_handleaed, and the BPM number both run at the true period of 60/hr seconds, which is (60/hr)/0.03, or
// 2000/hr columns. _spacing plus complexlen only equals 2000/hr near an hr of 73, so everywhere else the drawn
// rate drifts off the beep and the monitor lies.
// we instead derive the true period, as _spacing times 2.2222, because 2000/900 is 2.2222 and 1/(15*0.03) is
// 2.2222, and set the inter-beat gap to the true period minus complexlen, so one beat is exactly 2000/hr columns
// and the waveform ticks in lock-step with the beep and the BPM readout. at extreme tachycardia the fixed-width
// complex cannot fit the period, so the gap floors at a small value and the rate degrades gracefully.
// c. a time-anchored scroll. we trim the buffer front by floor(CBA_missionTime / 0.03) mod trueperiod, so column 0
// tracks real time: the beats land at their true instants and the trace scrolls continuously and wraps, instead
// of redrawing identical columns every sweep.
// _this is [_rhythm, _spacing, _arrayOffset].
params ["_rhythm", "_spacing", "_arrayOffset"];

// proxy translation. ACM hands us the rhythm from its own state, ACM_circulation_Cardiac_RhythmState, and for a
// custom rhythm that state holds a proxy rather than our code: torsades, 102, proxies as PVT, 3, so ACM treats it
// as a shockable arrest. see fn_rhythmset.
// if we drew straight from _rhythm we would render the proxy, so torsades would appear as PVT or vt, which is
// exactly the bug where torsades immediately shows vt. so if the target patient of the monitor is actually in a
// custom rhythm, draw that, because rhythmget returns 100 to 104, and let the delegation below take it to our
// polymorphic generator. native rhythms are unaffected, because rhythmget returns the same native code.
private _tgtRhythm = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
if (!isNull _tgtRhythm) then {
    private _effective = [_tgtRhythm] call ACME_fnc_rhythmGet;
    // CPR and ACM's post-shock VF/asystole display states have visual precedence. A custom rhythm only replaces
    // the native proxy while ACM is otherwise drawing the proxy/organized rhythm itself.
    if (_effective >= 100 && {!(_rhythm in [-1,1,2])}) then { _rhythm = _effective; };
};

// defensive. if ACM handed us a bad spacing, such as an hr of 0 where 60/hr upstream produced a non-finite value,
// treat it as a flatline rather than propagating nan into the step-spacing loops.
if (!(_spacing isEqualType 0) || {!(finite _spacing)} || {_spacing < 0}) then { _spacing = 0 };

// Rhythm changes are immediate. The monitor display loop already splices a changed waveform into the remainder of
// the active sweep, so do not defer morphology until an isoelectric segment or the next sweep.
private _tgtLatch = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
if (!isNull _tgtLatch) then {
    _tgtLatch setVariable ["ACME_AED_EKGVisualRhythm", _rhythm, false];
    _tgtLatch setVariable ["ACME_AED_EKGPendingRhythm", -999, false];
    _tgtLatch setVariable ["ACME_AED_EKGPendingSince", -1, false];
};

// our custom rhythms: AFib-RVR at 100, atrial tach at 101, torsades at 102, controlled AFib at 103 and SVT at
// 104.
if (_rhythm >= 100) exitWith {
    private _g = [_rhythm, _spacing, _arrayOffset] call ACME_fnc_genRhythmEKG;
    [_tgtRhythm, _g select 0, _g select 1] call ACME_fnc_ecgArtifactApply
};

private _maxLength = 176;
private _dt = 0.03;  // seconds per monitor column, which is the sweep tick.

// the true beat period in columns is (60 / hr) / _dt. stock ACM passes a rounded, gap-like spacing, which loses
// precision and does not include the fixed QRS and t complex width. prefer the current monitor or display hr from
// the target patient, then fall back to the historical spacing conversion.
private _tgtForRate = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
private _rateHR = 0;
if (!isNull _tgtForRate) then {
    _rateHR = [_tgtForRate] call ACM_circulation_fnc_getEKGHeartRate;
    if (_rateHR <= 0 && {_rhythm in [0,4]}) then { _rateHR = _tgtForRate getVariable ["ace_medical_heartRate", 0]; };
};
private _scale = missionNamespace getVariable ["ACME_rhythm_ekgPeriodScale", 2.2222];
private _truePeriod = if (_rateHR > 0) then { round ((60 / _rateHR) / _dt) } else { if (_spacing > 0) then { round ((_spacing max 1) * _scale) } else { _spacing } };
private _blockPeriod = 0;  // one beat block in columns, set per organized rhythm. 0 means noise or flat.
private _rPhase = 0;  // the block-phase, the column within a beat block, of the r spike, for the beep lock.

private _fnc_generateStepSpacingArray = {
    params ["_spacing"];
    private _stepSpacingArray = [];
    if (_spacing > 4) then {
        for "_i" from 0 to (ceil(_spacing / 4)) do {
            _stepSpacingArray = _stepSpacingArray + [(random [-2, 0, 2]),(random [-2, 0, 2]),(random [-2, 0, 2]),(random [-2, 0, 2])];
        };
    } else {
        _stepSpacingArray = [(random [-2, 0, 2]),(random [-2, 0, 2]),(random [-2, 0, 2]),(random [-2, 0, 2])];
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

// the inter-beat gap that makes the gap plus the complex equal the true period. it is floored, so the complex
// always fits.
private _fnc_gapFor = { params ["_len"]; (((_truePeriod - _len) max 2)) };

private _rhythmArray = [];
private _safeSpacingArray = [];

switch (_rhythm) do {
    case -1: {  // CPR.
        private _cleanRhythmStep = [0,-5,-10,-20,-40 + (random 5),-45 + (random 5),-45 + (random 5),-45 + (random 5),-45 + (random 5),-45 + (random 5),-45 + (random 5),-40 + (random 5),-20,-10,-5];
        private _noiseRange = 8;
        private _gap = [count _cleanRhythmStep] call _fnc_gapFor;
        _blockPeriod = (count _cleanRhythmStep) + _gap;
        _rPhase = _gap + (_cleanRhythmStep find (selectMin _cleanRhythmStep));
        private _repeat = ceil(176 / _blockPeriod) + 1;
        for "_i" from 0 to _repeat do {
            _rhythmArray = _rhythmArray + ([_gap] call _fnc_generateStepSpacingArray) + ([_cleanRhythmStep, _noiseRange] call _generateNoisyRhythmStep);
            _safeSpacingArray = _safeSpacingArray + ([_gap, true] call _generateSafeSpacing) + ([count _cleanRhythmStep] call _generateSafeSpacing);
        };
    };
    case 5: {  // true PEA: organized electrical complexes with no mechanical output. Broad, abnormal morphology.
        private _cleanRhythmStep = [0,-2,-8,-20,-38,-50,-48,-36,-16,5,18,27,23,14,6,1,0];
        private _noiseRange = 3.5;
        private _gap = [count _cleanRhythmStep] call _fnc_gapFor;
        _blockPeriod = (count _cleanRhythmStep) + _gap;
        _rPhase = _gap + (_cleanRhythmStep find (selectMin _cleanRhythmStep));
        private _repeat = ceil(176 / _blockPeriod) + 1;
        for "_i" from 0 to _repeat do {
            // Keep R-R spacing exact, but make each PEA complex a little less sterile: mild amplitude drift,
            // baseline wander, and an occasional small notch/artifact in the late QRS/ST segment.
            private _amp = random [0.90, 1.0, 1.10];
            private _base = random [-2, 0, 2];
            private _beat = _cleanRhythmStep apply {(_x * _amp) + _base};
            if ((random 1) < 0.22) then {
                private _j = 7 + floor (random 4);
                _beat set [_j, (_beat select _j) + random [-6, 0, 6]];
            };
            _rhythmArray = _rhythmArray + ([_gap] call _fnc_generateStepSpacingArray) + ([_beat, _noiseRange] call _generateNoisyRhythmStep);
            _safeSpacingArray = _safeSpacingArray + ([_gap, true] call _generateSafeSpacing) + ([count _cleanRhythmStep] call _generateSafeSpacing);
        };
    };
    case 0: {  // sinus.
        // the full-width ACM sinus is 15 columns, which cannot physically fit very fast rates on a 0.03 s per column
        // sweep. use a compact narrow-complex beat at tachy rates, so the r-r spacing can still match the displayed
        // hr.
        private _cleanRhythmStep = if (_truePeriod < 18) then {
            [0,-4,-40,22,4,-4,2,0]
        } else {
            [0,-1,-5,2,-4,-40,25,5,0,-5,-7,-1,5,4,0.8]
        };
        private _noiseRange = 3;
        private _gap = [count _cleanRhythmStep] call _fnc_gapFor;
        _blockPeriod = (count _cleanRhythmStep) + _gap;
        _rPhase = _gap + (_cleanRhythmStep find (selectMin _cleanRhythmStep));
        private _repeat = ceil(176 / _blockPeriod) + 1;
        for "_i" from 0 to _repeat do {
            _rhythmArray = _rhythmArray + ([_gap] call _fnc_generateStepSpacingArray) + ([_cleanRhythmStep, _noiseRange] call _generateNoisyRhythmStep);
            _safeSpacingArray = _safeSpacingArray + ([_gap, true] call _generateSafeSpacing) + ([count _cleanRhythmStep] call _generateSafeSpacing);
        };
    };
    case 1: {  // asystole. it is flat noise and regenerates each pass anyway, so no phase is needed.
        private _cleanRhythmStep = [0];
        private _noiseRange = 3;
        private _repeat = ceil(176 / (count _cleanRhythmStep)) + 1;
        for "_i" from 0 to _repeat do {
            _rhythmArray = _rhythmArray + ([_cleanRhythmStep, _noiseRange] call _generateNoisyRhythmStep);
        };
    };
    case 2: {  // vf. it is chaotic noise and regenerates each pass anyway, so no phase is needed.
        private _cleanRhythmStep = [0];
        private _noiseRange = 30;
        private _repeat = ceil(176 / (count _cleanRhythmStep)) + 1;
        for "_i" from 0 to _repeat do {
            _rhythmArray = _rhythmArray + ([_cleanRhythmStep, _noiseRange] call _generateNoisyRhythmStep);
        };
    };
    case 3;  // PVT.
    case 4: {  // vt, with broad complexes. it locks to the true period with a short gap, so the drawn rate
              // it tracks hr. ACM tiled them back to back, which reads as a fixed rate of about 220 a minute.
        private _cleanRhythmStep = [5,-30,-47,-49,-49,-49,-44,-39,-30];
        private _noiseRange = 3;
        private _gap = [count _cleanRhythmStep] call _fnc_gapFor;
        _blockPeriod = (count _cleanRhythmStep) + _gap;
        _rPhase = _gap + (_cleanRhythmStep find (selectMin _cleanRhythmStep));
        private _repeat = ceil(176 / _blockPeriod) + 1;
        for "_i" from 0 to _repeat do {
            private _cleanRhythmStepRandomized = +_cleanRhythmStep;
            _cleanRhythmStepRandomized set [0, ((_cleanRhythmStepRandomized select 0) + (2 - (random 4)))];
            _rhythmArray = _rhythmArray + ([_gap] call _fnc_generateStepSpacingArray) + ([_cleanRhythmStepRandomized, _noiseRange] call _generateNoisyRhythmStep);
            _safeSpacingArray = _safeSpacingArray + ([_gap, true] call _generateSafeSpacing) + ([count _cleanRhythmStep] call _generateSafeSpacing);
        };
    };
};

// the phase: lock the r spike to ACM's own AED beep timestamp. ACM owns the audio, and ACME only aligns the
// generated waveform buffer to ACM_circulation_AED_Pads_LastBeep.
if (_blockPeriod > 0) then {
    private _lastBeat = -1;
    private _tgt = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
    if (!isNull _tgt) then {
        _lastBeat = _tgt getVariable ["ACM_circulation_AED_Pads_LastBeep", -1];
    };
    if (_lastBeat >= 0) then {
        private _beatPhase = floor ((CBA_missionTime - _lastBeat) / _dt);
        _arrayOffset = (_rPhase + _beatPhase) mod _blockPeriod;
    } else {
        _arrayOffset = (floor (CBA_missionTime / _dt)) mod _blockPeriod;
    };
};
if (_arrayOffset > 0) then {
    _arrayOffset = _arrayOffset min ((count _rhythmArray) - 1);
    _rhythmArray deleteRange [0, _arrayOffset];
    if (_arrayOffset < count _safeSpacingArray) then { _safeSpacingArray deleteRange [0, _arrayOffset]; };
};
if (count _safeSpacingArray < 1) then { _safeSpacingArray resize [_maxLength, true]; };
_rhythmArray resize [_maxLength, 0];

[_tgtForRate, _rhythmArray, _safeSpacingArray] call ACME_fnc_ecgArtifactApply
