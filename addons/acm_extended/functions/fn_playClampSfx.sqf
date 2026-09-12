// the roller clamp tick, with an adaptive rate.
// slow, fine control, with the ticks spaced apart, gives one tick per percent, and a fast slide gives every other
// percent, hard-capped by a minimum interval.
// the pitch curve is reversed: moving the clamp down is heard as higher pitched, and moving it up as lower
// pitched.
params [["_position", 0.5]];

private _pct = round (((_position max 0) min 1) * 100);
private _last = uiNamespace getVariable ["ACME_RollerClamp_SfxPct", -1];
if (_pct == _last) exitWith {false};
uiNamespace setVariable ["ACME_RollerClamp_SfxPct", _pct];
if (_last < 0) exitWith {false};  // baseline sync on dialog open: no sound
// the CBA setting: sounds off entirely. the pct bookkeeping above stays current, so re-enabling mid-session does
// not fire a burst of stale ticks.
if !(missionNamespace getVariable ["ACME_infusion_clampSfxEnabled", true]) exitWith {false};

private _now = diag_tickTime;
private _lastPlay = uiNamespace getVariable ["ACME_RollerClamp_SfxLastPlay", -1];
private _slowThreshold = missionNamespace getVariable ["ACME_infusion_clampSfxSlowThreshold", 0.12];
private _minInterval = missionNamespace getVariable ["ACME_infusion_clampSfxMinInterval", 0.06];

private _slow = (_lastPlay < 0) || {(_now - _lastPlay) > _slowThreshold};
private _play = true;
if (!_slow) then {
    // a fast slide: only even percents, and never faster than the hard cap.
    if ((_pct mod 2) != 0) then {_play = false};
    if (_play && {(_now - _lastPlay) < _minInterval}) then {_play = false};
};
if (!_play) exitWith {false};

private _rel = _pct / 100;
private _pitchMax = missionNamespace getVariable ["ACME_infusion_clampSfxPitchMax", 1.5];
private _volMin = missionNamespace getVariable ["ACME_infusion_clampSfxVolMin", 0.65];
private _pitch = 1 + ((_pitchMax - 1) * _rel);
private _vol = _volMin + ((1 - _volMin) * _rel);

uiNamespace setVariable ["ACME_RollerClamp_SfxLastPlay", _now];
playSoundUI [missionNamespace getVariable ["ACME_infusion_clampSfxFile", "\acm_extended\sound\roller_clamp_sfx.ogg"], _vol, _pitch];
true
