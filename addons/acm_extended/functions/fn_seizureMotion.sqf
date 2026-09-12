// seizure body motion. there is an important limitation: arma 3 gives script no per-bone control on a living or
// posed unit. there is no runtime skeleton access and no additive animation blending, so individually twitching
// a wrist, hand or foot is not possible from sqf, however much we would want it. the only body levers are the
// heading, through setdir, and ragdoll.
// so the convulsion is synthesized as a tight, fast heading tremor about a fixed base heading, which is a shudder
// in place rather than a slew to random directions, and that slew is what the old wide-yaw version looked like.
// it is punctuated by occasional ACE ragdoll flops. ragdoll is what actually moves and re-headings the body, so
// it is rare and is suppressed entirely for elevated-head patients, because a flop would throw them out of the
// pose. a short settle phase runs first, so the onset collapse reads as a fall. it runs while
// ACME_lido_seizureState is "active".
// the phase sub-state machine, per patient, runs settle, then burst, then either a pause or a ragdoll, then burst
// again, and so on.
// settle has no thrash. it lets the onset or recurrence ragdoll collapse play out.
// burst is a tight, fast heading tremor about the fixed base heading.
// pause is still, held at the fixed rest heading, for a short random pause.
// ragdoll is an ACE unconscious-ragdoll flop, never for elevated-head patients, and the heading is re-baselined
// afterward.
// everything here is CBA-tunable, because animation fidelity in arma cannot be judged from outside the game. the
// knobs are:
// ACME_seizure_motionEnabled, 1 or 0, the master toggle, defaulting to 1.
// ACME_seizure_jerkHz, in hz, the tremor frequency during a burst, defaulting to 11, a fast shudder.
// ACME_seizure_yawAmp, in degrees, the peak heading tremor either side of rest, defaulting to 2.0, which is tight
// and does not spin.
// ACME_seizure_yawChaos, 0 to 1, the random jitter fraction layered on the tremor, defaulting to 0.5.
// ACME_seizure_burstMin and burstMax, in seconds, the random tremor-burst length range, defaulting to 0.8 to 2.2,
// which is twitchy.
// ACME_seizure_pauseMin and pauseMax, in seconds, the random still-pause length range, defaulting to 0.6 to 1.6.
// ACME_seizure_ragdollChance, 0 to 1, the chance a burst ends in a flop rather than a pause, defaulting to 0.12,
// and 0 near head-up.
// ACME_seizure_ragdollDur, in seconds, the hold time while a flop settles before resuming, defaulting to 2.
// ACME_seizure_settleDur, in seconds, the initial settle before the first burst, defaulting to 1.5.
// ACME_seizure_camShake, 1 or 0, shakes the camera if the patient is a local player, defaulting to 1.
// call it as [_patient, _on] call ACME_fnc_seizureMotion.
params ["_patient", ["_on", true]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {};  // run on the owner. the orientation and the ragdoll propagate to clients normally.

// a stop request, or the master toggle off: tear the handler down and let the resting pose stand.
// ACME_seizure_animEnabled is the addon-option checkbox and it governs the ANIMATION only. the seizure itself,
// the loss of consciousness, the vitals and every consequence are untouched by it, because a convulsion the
// player cannot see is still a convulsion the casualty is having.
// ACME_seizure_motionEnabled is the older numeric knob, 1 or 0, and it is kept so a mission that already sets it
// keeps working. either one being off stops the motion.
if (!_on
    || {!(missionNamespace getVariable ["ACME_seizure_animEnabled", true])}
    || {(missionNamespace getVariable ["ACME_seizure_motionEnabled", 1]) == 0}) exitWith {
    private _h = _patient getVariable ["ACME_seizure_motionPFH", -1];
    if (_h >= 0) then {
        _h call CBA_fnc_removePerFrameHandler;
        _patient setVariable ["ACME_seizure_motionPFH", -1];
        if (alive _patient) then { _patient setDir (_patient getVariable ["ACME_seizure_motionBaseDir", getDir _patient]); };
        if (_patient == ACE_player) then { resetCamShake; };
    };
};

if ((_patient getVariable ["ACME_seizure_motionPFH", -1]) >= 0) exitWith {};  // already convulsing.

// the first phase is a short settle, so the collapse plays before the body starts thrashing.
_patient setVariable ["ACME_seizure_motionBaseDir", getDir _patient];
_patient setVariable ["ACME_seizure_motionPhase", "settle"];
_patient setVariable ["ACME_seizure_motionPhaseEnd", CBA_missionTime + (missionNamespace getVariable ["ACME_seizure_settleDur", 1.5])];

// the next burst-end time is drawn from the burst-length range. it is self-contained, with no outer locals, so it
// is safe to call in the pfh.
private _fnBurstEnd = {
    private _bMin = missionNamespace getVariable ["ACME_seizure_burstMin", 0.8];
    private _bMax = missionNamespace getVariable ["ACME_seizure_burstMax", 2.2];
    CBA_missionTime + _bMin + (random ((_bMax - _bMin) max 0))
};

private _h = [{
    params ["_args", "_handle"];
    _args params ["_patient", "_fnBurstEnd"];

    // end the convulsion the instant the seizure leaves the active phase, or the patient is gone.
    if (isNull _patient || {!alive _patient} || {(_patient getVariable ["ACME_lido_seizureState", ""]) != "active"}) exitWith {
        if (!isNull _patient && {alive _patient}) then {
            _patient setDir (_patient getVariable ["ACME_seizure_motionBaseDir", getDir _patient]);
        };
        if (!isNull _patient && {_patient == ACE_player}) then { resetCamShake; };
        _handle call CBA_fnc_removePerFrameHandler;
        _patient setVariable ["ACME_seizure_motionPFH", -1];
    };

    // while mounted in a vehicle, do not thrash, through setdir, or flop the body, because it fights the seat
    // animation. hold this frame and resume the convulsion once they are out. the seizure state and its vitals keep
    // running regardless.
    if (!isNull objectParent _patient) exitWith {};

    // head-elevated patients are held reclined by an attachment whose orientation we set, and a setdir tremor here
    // fights that hold and can jitter the pose. the elevation must be undisturbed by the seizure, because only
    // another person lowers them, so the body motion is skipped entirely for elevated patients. their seizure is
    // still real, because the vitals, the apnea and the erratic rr, run regardless. we simply do not physically
    // thrash a body that is being held in place.
    if (_patient getVariable ["ACME_headElevated", false]) exitWith {};

    private _now      = CBA_missionTime;
    private _phase    = _patient getVariable ["ACME_seizure_motionPhase", "burst"];
    private _phaseEnd = _patient getVariable ["ACME_seizure_motionPhaseEnd", 0];

    // the phase transitions.
    if (_now >= _phaseEnd) then {
        switch (_phase) do {
            case "settle": {
                // B39 generalized tonic-clonic sequence: collapse/settle is followed by a sustained
                // tonic phase before clonic jerking begins. Arma has no per-bone additive control, so
                // tonic rigidity is represented by a fixed body heading plus stronger local camera shake.
                _phase = "tonic";
                private _tMin = missionNamespace getVariable ["ACME_seizure_tonicMin", 7];
                private _tMax = missionNamespace getVariable ["ACME_seizure_tonicMax", 13];
                _phaseEnd = _now + _tMin + random ((_tMax - _tMin) max 0);
                _patient setVariable ["ACME_seizure_motionBaseDir", getDir _patient];
                if (_patient == ACE_player) then {addCamShake [7, (_phaseEnd - _now), 24];};
            };
            case "tonic": {
                _phase = "burst";
                _phaseEnd = call _fnBurstEnd;
                _patient setVariable ["ACME_seizure_motionBaseDir", getDir _patient];
            };
            case "burst": {
                // end a burst into either a still pause or, occasionally, a ragdoll flop. ragdoll is what actually moves the body,
                // and re-headings it, so it is rare now, and suppressed entirely when the head is elevated, because a flop there
                // would throw the patient out of the elevated pose and re-point them. that is exactly the seize, turn, seize
                // behavior that looked wrong. elevated-head patients simply tremor.
                private _headElev = _patient getVariable ["ACME_headElevated", false];
                private _ragChance = missionNamespace getVariable ["ACME_seizure_ragdollChance", 0.12];
                if (!_headElev && {random 1 < _ragChance}) then {
                    _phase = "ragdoll";
                    [_patient] call ACME_fnc_forceRagdoll;  // an off-then-on toggle gives a fresh ragdoll flop.
                    _phaseEnd = _now + (missionNamespace getVariable ["ACME_seizure_ragdollDur", 2]);
                } else {
                    _phase = "pause";
                    private _pMin = missionNamespace getVariable ["ACME_seizure_pauseMin", 0.6];
                    private _pMax = missionNamespace getVariable ["ACME_seizure_pauseMax", 1.6];
                    _phaseEnd = _now + _pMin + (random ((_pMax - _pMin) max 0));
                };
            };
            case "pause": {
                _phase = "burst";
                _phaseEnd = call _fnBurstEnd;
            };
            case "ragdoll": {
                _phase = "burst";
                _phaseEnd = call _fnBurstEnd;
                _patient setVariable ["ACME_seizure_motionBaseDir", getDir _patient];  // re-baseline, because the flop moved the body.
            };
        };
        _patient setVariable ["ACME_seizure_motionPhase", _phase];
        _patient setVariable ["ACME_seizure_motionPhaseEnd", _phaseEnd];
    };

    // the per-frame body drive.
    // arma gives script no per-bone control on a living or posed unit: you cannot twitch a wrist or a hand
    // independently, because there is no runtime skeleton access and no additive blending. the only body levers are
    // the heading, through setdir, and ragdoll.
    // the old version thrashed the heading wide, at 7 degrees plus chaos, which read as the whole body slewing to
    // random directions, and worst of all under an elevated-head pose, which setdir fights. so the yaw is a tight,
    // fast tremor about a fixed heading now: a couple of degrees at high frequency reads as a convulsive shudder in
    // place rather than a spin, and the heading never wanders. the clonic character comes from the fast tremor plus
    // the periodic ragdoll flops, and the base heading is held rock-steady so the patient stays put.
    private _baseDir = _patient getVariable ["ACME_seizure_motionBaseDir", getDir _patient];
    if (_phase == "burst") then {
        private _jerkHz  = missionNamespace getVariable ["ACME_seizure_jerkHz", 11];  // fast: a shudder rather than a sway.
        private _yawAmp  = missionNamespace getVariable ["ACME_seizure_yawAmp", 2.0];  // tight: degrees rather than a slew.
        private _chaos   = (missionNamespace getVariable ["ACME_seizure_yawChaos", 0.5]) max 0 min 1;
        // two detuned oscillators plus a little noise make the tremor irregular, because a real convulsion is not a clean
        // sine, while staying small and centerd on the fixed base heading.
        private _t = _now;
        private _tremor = _yawAmp * (0.6 * (sin (360 * _jerkHz * _t)) + 0.4 * (sin (360 * (_jerkHz * 1.7) * _t)));
        private _jitter = _yawAmp * _chaos * ((random 2) - 1);
        _patient setDir (_baseDir + _tremor + _jitter);
    } else {
        // settle and pause hold at the fixed rest heading. ragdoll is left to the engine, so we do not fight the flop.
        if (_phase != "ragdoll") then { _patient setDir _baseDir; };
    };
}, 0, [_patient, _fnBurstEnd]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_seizure_motionPFH", _h];

// camera shake for a patient who is a local player. their own pov sells it, and observers see the body
// thrash.
if ((missionNamespace getVariable ["ACME_seizure_camShake", 1]) == 1 && {_patient == ACE_player}) then {
    addCamShake [5, 3600, 20];  // the active-phase teardown stops it through resetCamShake.
};
true
