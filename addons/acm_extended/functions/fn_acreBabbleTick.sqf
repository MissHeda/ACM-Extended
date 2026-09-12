// B65: brief, speech-aware ACRE babble pulses for awake obtundation.
//
// The old implementation selected ACME_Obtunded for essentially the whole obtunded episode, which made every
// spoken word garbled.  This scheduler does the opposite: normal language is the resting state and the synthetic
// language is selected only for short windows while the player is ACTUALLY SPEAKING.  Physiological severity
// controls pulse frequency and (more mildly) pulse duration:
//   improving SpO2/MAP -> shorter pulses with longer gaps;
//   worsening SpO2/MAP -> somewhat longer pulses with shorter gaps.
// Even at maximum severity the language is never intended to remain selected continuously.
//
// ACRE's public isSpeaking API reports both direct and radio speech, so the pulse only has an audible effect while
// the casualty is actively talking.
params [["_unit", objNull]];
if (!hasInterface) exitWith {};

if (isNull _unit) then {
    _unit = if (!isNil "ACE_player" && {!isNull ACE_player}) then {ACE_player} else {player};
};

private _now = diag_tickTime;

// Hard gate first, before any scheduler state.  Master OFF means immediate language restoration, regardless of
// manual/debug obtundation or stale ACME_obtunded variables.
private _validState = (missionNamespace getVariable ["ACME_sys_obtunded", false])
    && {missionNamespace getVariable ["ACME_acre_babbleEnable", false]}
    && {missionNamespace getVariable ["ACME_acre_present", false]}
    && {!isNull _unit}
    && {_unit isEqualTo (if (!isNil "ACE_player" && {!isNull ACE_player}) then {ACE_player} else {player})}
    && {alive _unit}
    && {_unit getVariable ["ACME_obtunded", false]}
    && {!(_unit getVariable ["ACE_isUnconscious", false])}
    && {!isNil "acre_api_fnc_isSpeaking"}
    && {!isNil "acre_api_fnc_babelSetSpeakingLanguage"};

if (!_validState) exitWith {
    [false] call ACME_fnc_acreBabbleSet;
    uiNamespace setVariable ["ACME_acre_babbleWasSpeaking", false];
    uiNamespace setVariable ["ACME_acre_babbleNextPulse", -1];
    uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];
};

// 25 Hz is responsive enough to clip parts of words without running the ACRE getter every rendered frame.
private _guardAt = uiNamespace getVariable ["ACME_acre_babbleGuardAt", 0];
if (_now < _guardAt) exitWith {};
uiNamespace setVariable ["ACME_acre_babbleGuardAt", _now + (missionNamespace getVariable ["ACME_acre_babbleTickSec", 0.04])];

// Existing lucid windows are genuinely lucid for speech too.  They are not allowed to carry an old pulse through.
if (uiNamespace getVariable ["ACME_obtunded_lucidActive", false]) exitWith {
    [false] call ACME_fnc_acreBabbleSet;
    uiNamespace setVariable ["ACME_acre_babbleWasSpeaking", false];
    uiNamespace setVariable ["ACME_acre_babbleNextPulse", -1];
    uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];
};

private _speaking = [_unit] call acre_api_fnc_isSpeaking;
if (!_speaking) exitWith {
    // Stop mid-pulse the instant speech ends.  We do not leave the player parked in the synthetic language during
    // silence, and the next spoken phrase gets a fresh start delay instead of an immediate garbled first word.
    [false] call ACME_fnc_acreBabbleSet;
    uiNamespace setVariable ["ACME_acre_babbleWasSpeaking", false];
    uiNamespace setVariable ["ACME_acre_babbleNextPulse", -1];
    uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];
};

// Physiology only needs to be sampled twice per second.  Severity is the worse of oxygenation and perfusion,
// normalized across the same obtundation/recovery bands used by fn_obtundedAuto.
private _severityAt = uiNamespace getVariable ["ACME_acre_babbleSeverityAt", 0];
private _severity = uiNamespace getVariable ["ACME_acre_babbleSeverity", 0];
if (_now >= _severityAt) then {
    private _spo2 = _unit getVariable ["ace_medical_spo2", 97];
    private _bp = if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
        [_unit] call ace_medical_status_fnc_getBloodPressure
    } else {
        [80, 120]
    };
    _bp params [["_dia", 80], ["_sys", 120]];
    private _map = _dia + ((_sys - _dia) / 3);

    private _spo2Recover = missionNamespace getVariable ["ACME_obtunded_spo2Recover", 92];
    private _spo2Floor   = missionNamespace getVariable ["ACME_obtunded_spo2EnterLo", 70];
    private _mapRecover  = missionNamespace getVariable ["ACME_obtunded_mapRecover", 70];
    private _mapFloor    = missionNamespace getVariable ["ACME_obtunded_mapEnterLo", 55];

    private _spo2Severity = linearConversion [_spo2Recover, _spo2Floor, _spo2, 0, 1, true];
    private _mapSeverity  = linearConversion [_mapRecover, _mapFloor, _map, 0, 1, true];
    _severity = (_spo2Severity max _mapSeverity) max 0 min 1;

    uiNamespace setVariable ["ACME_acre_babbleSeverity", _severity];
    uiNamespace setVariable ["ACME_acre_babbleSeverityAt", _now + 0.5];
};

private _wasSpeaking = uiNamespace getVariable ["ACME_acre_babbleWasSpeaking", false];
if (!_wasSpeaking) exitWith {
    uiNamespace setVariable ["ACME_acre_babbleWasSpeaking", true];

    // Do not always trash the first word.  More severe obtundation starts interfering sooner, but still after a
    // small randomized clean lead-in.
    private _startMin = linearConversion [0, 1, _severity,
        missionNamespace getVariable ["ACME_acre_babbleStartMildMin", 0.55],
        missionNamespace getVariable ["ACME_acre_babbleStartSevereMin", 0.18], true];
    private _startRand = linearConversion [0, 1, _severity,
        missionNamespace getVariable ["ACME_acre_babbleStartMildRand", 0.85],
        missionNamespace getVariable ["ACME_acre_babbleStartSevereRand", 0.40], true];
    uiNamespace setVariable ["ACME_acre_babbleNextPulse", _now + _startMin + random _startRand];
    uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];
};

private _pulseActive = uiNamespace getVariable ["ACME_acre_babbleActive", false];
private _pulseUntil = uiNamespace getVariable ["ACME_acre_babblePulseUntil", -1];

if (_pulseActive) then {
    if (_pulseUntil < 0 || {_now >= _pulseUntil}) then {
        [false] call ACME_fnc_acreBabbleSet;
        uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];

        // Better physiology = a longer clean interval.  Worse physiology = more frequent corruption.
        private _gapMin = linearConversion [0, 1, _severity,
            missionNamespace getVariable ["ACME_acre_babbleGapMildMin", 7.0],
            missionNamespace getVariable ["ACME_acre_babbleGapSevereMin", 1.6], true];
        private _gapRand = linearConversion [0, 1, _severity,
            missionNamespace getVariable ["ACME_acre_babbleGapMildRand", 5.0],
            missionNamespace getVariable ["ACME_acre_babbleGapSevereRand", 1.8], true];
        uiNamespace setVariable ["ACME_acre_babbleNextPulse", _now + _gapMin + random _gapRand];
    };
} else {
    private _nextPulse = uiNamespace getVariable ["ACME_acre_babbleNextPulse", -1];
    if (_nextPulse < 0) then {
        _nextPulse = _now + 0.5;
        uiNamespace setVariable ["ACME_acre_babbleNextPulse", _nextPulse];
    };

    if (_now >= _nextPulse) then {
        [true, true] call ACME_fnc_acreBabbleSet;
        if (uiNamespace getVariable ["ACME_acre_babbleActive", false]) then {
            // Pulse length changes less aggressively than the gap.  The effect should clip a few syllables/words,
            // not turn a whole transmission into permanent Babel even in the worst physiology.
            private _durMin = linearConversion [0, 1, _severity,
                missionNamespace getVariable ["ACME_acre_babblePulseMildMin", 0.18],
                missionNamespace getVariable ["ACME_acre_babblePulseSevereMin", 0.36], true];
            private _durRand = linearConversion [0, 1, _severity,
                missionNamespace getVariable ["ACME_acre_babblePulseMildRand", 0.12],
                missionNamespace getVariable ["ACME_acre_babblePulseSevereRand", 0.24], true];
            uiNamespace setVariable ["ACME_acre_babblePulseUntil", _now + _durMin + random _durRand];
        } else {
            // If ACRE rejected the switch, back off instead of retrying every 40 ms.
            uiNamespace setVariable ["ACME_acre_babbleNextPulse", _now + 1.0];
        };
    };
};
