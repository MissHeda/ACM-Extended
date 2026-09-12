// cabin motion: how much the world is moving under the hands of the medic right now.
// it returns a screen-space offset, [_dx, _dy], which the caller applies to the whole minigame panel.
// call it as [] call ACME_fnc_motionShake, which returns [_dx, _dy].
// there are four things, deliberately separate. lumping them together is what made the old version wallow like a
// boat.
// 1. vibration is always there. it is small, fast and harmonious, and it is the airframe humming. it is led by the
// 17 hz fuselage frequency, because that is what a black hawk actually feels like. it is felt rather than seen.
// 2. maneuver happens only when banking or pitching. it is large and slow, and it is what throws you across the
// cabin.
// 3. bumps are discrete, sharp and random, and they fire in bursts of up to three, because air is not smooth.
// 4. the envelope is the thing that makes it playable. everything above swells and lulls on a slow, irregular
// cycle. in the lulls the cabin settles and you get a window, a few seconds of calm to land the stick, seat the
// seal or find the space. that is the skill: reading the shake and moving when it gives you room, rather than
// fighting it. a constant shake is an obstacle and a breathing one is a decision.
// everything is smoothed and nothing snaps on or off. the bank ramps in and ramps out, the vibration tapers away
// as you slow to land, and a hover does not instantly become a cruise. abrupt state changes read as bugs rather
// than flight.
// some history: this did not compile for four builds, because of "(speed _veh) abs" where abs is prefix-only in
// sqf, and it silently returned nil. when it finally compiled it returned nan, because the phase was computed
// from diag_tickTime and reduced in 32-bit float, and a nan offset corrupts every control in the dialog. hence
// the accumulated phase, hence the finite check at the bottom, and hence the force switch. do not debug this by
// guessing.

// One sample per rendered frame keeps all procedure callers on the same motion phase.
private _unit = missionNamespace getVariable ["ACE_player", player];
private _enabled = missionNamespace getVariable ["ACME_motion_enable", true];
if (!_enabled || {isNull _unit}) exitWith {
    uiNamespace setVariable ["ACME_motion_output", [0,0]];
    uiNamespace setVariable ["ACME_motion_sampleFrame", -1];
    uiNamespace setVariable ["ACME_motion_vibS", 0];
    uiNamespace setVariable ["ACME_motion_manS", 0];
    [0,0]
};
private _veh = vehicle _unit;
private _now = diag_tickTime;
private _smooth = missionNamespace getVariable ["ACME_motion_interpolate", true];
private _smoothTau = missionNamespace getVariable ["ACME_motion_interpolationTime", 0.12];
private _key = [_unit, _veh, _smooth, _smoothTau, missionNamespace getVariable ["ACME_motion_force", 0]];
if ((uiNamespace getVariable ["ACME_motion_sampleFrame", -1]) == diag_frameNo && {
    (uiNamespace getVariable ["ACME_motion_sampleKey", []]) isEqualTo _key
}) exitWith {+(uiNamespace getVariable ["ACME_motion_output", [0,0]])};
private _lastTime = uiNamespace getVariable ["ACME_motion_sampleTime", -1];
private _reset = _lastTime < 0 || {_now - _lastTime > 0.5}
    || {!((uiNamespace getVariable ["ACME_motion_sampleKey", []]) isEqualTo _key)};
if (_reset) then {
    uiNamespace setVariable ["ACME_motion_output", [0,0]];
    uiNamespace setVariable ["ACME_motion_vibS", 0];
    uiNamespace setVariable ["ACME_motion_manS", 0];
    uiNamespace setVariable ["ACME_motion_bumpT0", -1e9];
    uiNamespace setVariable ["ACME_motion_nextBump", -1];
    uiNamespace setVariable ["ACME_motion_burstLeft", 0];
};
private _dt = (if (_reset) then {diag_deltaTime} else {_now - _lastTime}) min 0.1 max 0;
uiNamespace setVariable ["ACME_motion_sampleTime", _now];
uiNamespace setVariable ["ACME_motion_sampleFrame", diag_frameNo];
uiNamespace setVariable ["ACME_motion_sampleKey", _key];

// the test switch. 1 is as if cruising and 2 is as if in a hard bank. it works on foot, from the debug
// console.
private _force  = missionNamespace getVariable ["ACME_motion_force", 0];
private _onFoot = _veh isEqualTo _unit;

private _isAir   = false;
private _speed   = 0;
private _vibTgt  = 0;
private _manTgt  = 0;

if (!_onFoot || {_force > 0}) then {
    _isAir = (_veh isKindOf "Air") || {_onFoot && {_force > 0}};
    _speed = if (_onFoot) then {0} else {abs (speed _veh)};  // km/h.

    // the vibration target.
    // the mh-60 is the airframe people actually fly medevac in. it cruises around 260 to 280 km/h, so that is where
    // the shake should peak. at 220 the whole realistic cruise band sat pinned at maximum with no dynamic range
    // left, and 260 felt identical to 280. the speed scales continuously right across the band you actually fly
    // now.
    private _vMax = missionNamespace getVariable ["ACME_motion_maxSpeed", 260];
    _vibTgt = linearConversion [0, _vMax, _speed, 0, 1, true];
    if (!_isAir && {!_onFoot}) then {
        _vibTgt = linearConversion [0, 60, _speed, 0, 1, true];
        if (_speed > 1 && {!(isOnRoad (getPosATL _veh))}) then { _vibTgt = _vibTgt * 1.6; };
    };

    // the airspeed taper. below cruise the airframe settles, so slowing down makes the buzz fall away and landing
    // removes it. this is what makes a descent feel like a descent rather than a switch being thrown at
    // touchdown.
    private _tSpd = missionNamespace getVariable ["ACME_motion_taperSpeed", 100];
    _vibTgt = _vibTgt * (linearConversion [15, _tSpd, _speed, 0.15, 1, true]);

    // rotors turning on the deck is a gentle hum. it is not silence and it is not a cruise either.
    if (_isAir && {!_onFoot} && {isEngineOn _veh}) then {
        _vibTgt = _vibTgt max (missionNamespace getVariable ["ACME_motion_rotorIdle", 0.12]);
    };
    _vibTgt = _vibTgt min 1.6;

    // the maneuver target.
    // it reads the real attitude of the airframe off its vectorup. level is about [0,0,1], and the more it tilts, the
    // more of that vector spills into x and y, and that is the bank and pitch, straight from the engine.
    if (!_onFoot) then {
        (vectorUp _veh) params ["_vx", "_vy"];
        private _tilt = sqrt ((_vx * _vx) + (_vy * _vy));
        _manTgt = linearConversion [0.05, 0.60, _tilt, 0, 1, true];
    };

    if (_force > 0) then {
        _vibTgt = 0.75;
        _manTgt = if (_force >= 2) then {1} else {0};
    };
};

// smoothing: nothing snaps.
// it is an exponential approach toward the target. the bank ramps in and ramps out, and the vibration fades as you
// slow. a hover does not become a cruise between one frame and the next.
private _vib = uiNamespace getVariable ["ACME_motion_vibS", 0];
private _man = uiNamespace getVariable ["ACME_motion_manS", 0];
private _tauV = missionNamespace getVariable ["ACME_motion_vibTau", 1.10];  // seconds to settle, for the vibration.
private _tauM = missionNamespace getVariable ["ACME_motion_manTau", 0.75];  // seconds to settle, for the bank.
_vib = _vib + ((_vibTgt - _vib) * ((_dt / _tauV) min 1));
_man = _man + ((_manTgt - _man) * ((_dt / _tauM) min 1));
if (_vib < 0.0005) then { _vib = 0; };
if (_man < 0.0005) then { _man = 0; };
uiNamespace setVariable ["ACME_motion_vibS", _vib];
uiNamespace setVariable ["ACME_motion_manS", _man];

if (_vib <= 0.004 && {_man <= 0.004}) exitWith {
    private _rest = if (_smooth) then {[[0,0], uiNamespace getVariable ["ACME_motion_output", [0,0]], _dt, _smoothTau] call ACME_fnc_motionSmooth} else {[0,0]};
    if ((abs (_rest select 0) + abs (_rest select 1)) < 1e-6) then {_rest = [0,0];};
    uiNamespace setVariable ["ACME_motion_output", _rest];
    _rest
};

// the envelope: swell and lull, so there are openings.
// two slow oscillators at incommensurate rates, so the pattern never repeats and cannot be counted. their product
// swells and lulls. in a lull the cabin settles to envmin of full strength and you have a window, a few seconds
// of relative calm, which is your chance to commit. it applies to the vibration and the bank, so even a turning
// aircraft has moments where it steadies enough to work.
private _eA = uiNamespace getVariable ["ACME_motion_envA", random 360];
private _eB = uiNamespace getVariable ["ACME_motion_envB", random 360];
_eA = ((_eA + (_dt * (missionNamespace getVariable ["ACME_motion_envRateA", 0.17]) * 360)) % 360);
_eB = ((_eB + (_dt * (missionNamespace getVariable ["ACME_motion_envRateB", 0.29]) * 360)) % 360);
uiNamespace setVariable ["ACME_motion_envA", _eA];
uiNamespace setVariable ["ACME_motion_envB", _eB];

private _envMin = missionNamespace getVariable ["ACME_motion_envMin", 0.30];
private _swell  = (0.5 + (0.5 * (sin _eA))) * (0.62 + (0.38 * (0.5 + (0.5 * (sin _eB)))));
private _env    = _envMin + ((1 - _envMin) * _swell);

private _vibAmp = _vib * _env * (missionNamespace getVariable ["ACME_motion_vibAmplitude", 0.007]);
private _manAmp = _man * _env * (missionNamespace getVariable ["ACME_motion_manAmplitude", 0.055]);

// the spectrum.
// these are measured mh-60 cabin figures. the 4.3 hz rotor rocking is deliberately turned down and the 17.2 hz
// fuselage frequency leads, because 4.3 hz is the only component slow enough for the eye to read as motion, and
// letting it dominate is what made the panel sway. the buzz should lead, and the rocking should only underpin
// it.
private _aft = 0.5;
if (!_onFoot) then {
    private _mdl = _veh worldToModel (getPosWorld _unit);
    if (count _mdl > 1) then { _aft = linearConversion [2, -4, (_mdl select 1), 0, 1, true]; };
};
private _comps = [[4.3, 0.26], [17.2, 1.00], [34.4, 0.46], [51.6, 0.26], [81.0, 0.14 * (0.4 + _aft)]];
if (!_isAir) then { _comps = [[2.4, 0.32], [11.0, 1.00], [22.0, 0.40]]; };

// nyquist. components this frame rate cannot draw would alias into a slow phantom wobble that is not in the real
// spectrum at all, so they are folded into an rms-matched jitter instead, which is what they look like
// anyway.
private _nyq = (diag_fps max 1) * 0.45;

// the phase is accumulated and never taken from the clock. sin (diag_tickTime * 360 * hz) is an angle of a
// billion degrees an hour into a mission, reduced in 32-bit float, and it returns nan.
private _phases = uiNamespace getVariable ["ACME_motion_phases", []];
if ((count _phases) != (count _comps)) then { _phases = _comps apply {0}; };

private _dx = 0;
private _dy = 0;
private _buzz = 0;
{
    _x params ["_hz", "_w"];
    private _ph = (((_phases select _forEachIndex) + (_dt * _hz * 360)) % 360);
    _phases set [_forEachIndex, _ph];
    if (_hz < _nyq) then {
        _dx = _dx + (_vibAmp * _w * (sin _ph));
        _dy = _dy + (_vibAmp * _w * 0.82 * (cos _ph));
    } else {
        _buzz = _buzz + (_w * _w);
    };
} forEach _comps;
uiNamespace setVariable ["ACME_motion_phases", _phases];

// Smooth mode omits unresolved high-frequency jitter instead of drawing random jumps.
if (_buzz > 0 && {!_smooth}) then {
    private _bAmp = _vibAmp * (sqrt _buzz);
    _dx = _dx + (_bAmp * ((random 2) - 1));
    _dy = _dy + (_bAmp * ((random 2) - 1));
};

// the maneuver sway.
private _mph = uiNamespace getVariable ["ACME_motion_manPhase", 0];
_mph = ((_mph + (_dt * 1.1 * 360)) % 360);
uiNamespace setVariable ["ACME_motion_manPhase", _mph];
if (_manAmp > 0) then {
    _dx = _dx + (_manAmp * (sin _mph));
    _dy = _dy + (_manAmp * 0.7 * (cos (_mph * 0.83)));
};

// bumps: fired in bursts, then a cooldown.
// turbulence does not arrive as a metronome. you hit rough air and it hits you two or three times in quick
// succession, and then it is smooth again for a while. so there is a burst of up to three jolts a few tenths of a
// second apart, then a real cooldown before the air can hit you again. the cooldown is what protects the window,
// because if bumps could fire at any moment there would be no such thing as a safe moment to commit.
private _burst   = uiNamespace getVariable ["ACME_motion_burstLeft", 0];
private _nextB   = uiNamespace getVariable ["ACME_motion_nextBump", -1];
private _bumpT0  = uiNamespace getVariable ["ACME_motion_bumpT0", -1e9];
private _bumpVec = uiNamespace getVariable ["ACME_motion_bumpVec", [0, 0]];
private _bumpDur = missionNamespace getVariable ["ACME_motion_bumpDur", 0.20];

private _activity = (_vib + (_man * 1.5)) max 0;
if (_nextB < 0 || {_now > (_nextB + 20)}) then { _nextB = _now + 2 + (random 4); };  // arm, or re-arm.

if (_now >= _nextB && {_activity > 0.08}) then {
    if (_burst <= 0) then {
        _burst = 1 + (floor (random (missionNamespace getVariable ["ACME_motion_burstMax", 3])));
    };

    private _amp = (missionNamespace getVariable ["ACME_motion_bumpAmp", 0.022])
        * _activity * _env * (0.45 + (random 1.05));
    private _ang = random 360;
    _bumpVec = [_amp * (sin _ang), _amp * (cos _ang) * 1.25];  // biased vertical, because you mostly drop.
    uiNamespace setVariable ["ACME_motion_bumpVec", _bumpVec];
    uiNamespace setVariable ["ACME_motion_bumpT0", _now];
    _bumpT0 = _now;

    _burst = _burst - 1;
    if (_burst > 0) then {
        // still inside the burst, so the next hit lands almost immediately.
        _nextB = _now + (missionNamespace getVariable ["ACME_motion_burstGapMin", 0.13])
            + (random ((missionNamespace getVariable ["ACME_motion_burstGapMax", 0.34])
                     - (missionNamespace getVariable ["ACME_motion_burstGapMin", 0.13])));
    } else {
        // the burst is spent. now the air is smooth for a while, and the smoother the ride the longer that lasts.
        private _cdMin = missionNamespace getVariable ["ACME_motion_bumpCooldownMin", 4];
        private _cdMax = missionNamespace getVariable ["ACME_motion_bumpCooldownMax", 14];
        _nextB = _now + _cdMin + (random ((_cdMax - _cdMin) * (1 - ((_activity min 1) * 0.6))));
    };
};
uiNamespace setVariable ["ACME_motion_burstLeft", _burst];
uiNamespace setVariable ["ACME_motion_nextBump", _nextB];

private _bt = _now - _bumpT0;
if (_bt >= 0 && {_bt < _bumpDur}) then {
    // a snappy envelope: an instant hit, a hard cubic decay and one sharp rebound. it is a jolt rather than a
    // fade.
    private _k = 1 - (_bt / _bumpDur);
    private _e = (_k * _k * _k) * (cos ((_bt / _bumpDur) * 540));
    _bumpVec params ["_bvx", "_bvy"];
    _dx = _dx + (_bvx * _e);
    _dy = _dy + (_bvy * _e);
};

// the last line of defense. this goes straight into ctrlSetPosition, and one nan takes the whole panel with
// it.
if (!(finite _dx)) then { _dx = 0; };
if (!(finite _dy)) then { _dy = 0; };


// Filter before uiShakeApply places either visual controls or the hit-test body rectangle.
private _output = if (_smooth) then {
    [[_dx,_dy], uiNamespace getVariable ["ACME_motion_output", [0,0]], _dt, _smoothTau] call ACME_fnc_motionSmooth
} else {[_dx,_dy]};
uiNamespace setVariable ["ACME_motion_output", _output];
+_output
