// Phase 142: ACRE2 obtunded-babble language transaction.
//
// _this = [_on, _pulseAuthorized, _forceRestore]
// Only fn_acreBabbleTick is allowed to enable the synthetic language. Every caller may restore it.
// The transaction always owns a real restoration target before ACME_Obtunded can become the speaking language.
params [
    ["_on", true],
    ["_pulseAuthorized", false],
    ["_forceRestore", false]
];
if (!hasInterface) exitWith {};

private _id = missionNamespace getVariable ["ACME_acre_babbleId", "ACME_Obtunded"];
private _common = missionNamespace getVariable ["ACME_acre_commonId", "ACME_Common"];
private _player = if (!isNil "ACE_player" && {!isNull ACE_player}) then {ACE_player} else {player};
private _present = missionNamespace getVariable ["ACME_acre_present", false];

// Convert ACRE's current language result to a language key. Current ACRE source returns the numeric registry index
// even though the public API documentation describes a string, so both forms are accepted.
private _fnCurrentKey = {
    private _languages = missionNamespace getVariable ["acre_sys_core_languages", []];
    if !(_languages isEqualType []) then {_languages = [];};
    private _raw = call acre_api_fnc_babelGetSpeakingLanguageId;
    if (_raw isEqualType "") exitWith {_raw};
    if (_raw isEqualType 0 && {_raw >= 0} && {_raw < count _languages}) exitWith {
        (_languages select _raw) param [0, ""]
    };
    ""
};

if (_on) then {
    // Re-evaluate startup state if the master was enabled after ACRE/mission Babel initialization.
    if !(missionNamespace getVariable ["ACME_acre_babbleReady", false]) then {
        call ACME_fnc_acreBabbleInit;
    };

    private _valid = _pulseAuthorized
        && {missionNamespace getVariable ["ACME_sys_obtunded", false]}
        && {missionNamespace getVariable ["ACME_acre_babbleEnable", false]}
        && {_present}
        && {missionNamespace getVariable ["ACME_acre_babbleSafe", false]}
        && {missionNamespace getVariable ["ACME_acre_babbleReady", false]}
        && {!isNull _player}
        && {alive _player}
        && {_player getVariable ["ACME_obtunded", false]}
        && {!(_player getVariable ["ACE_isUnconscious", false])}
        && {!(uiNamespace getVariable ["ACME_obtunded_lucidActive", false])}
        && {!isNil "acre_api_fnc_isSpeaking"}
        && {[_player] call acre_api_fnc_isSpeaking}
        && {!isNil "acre_api_fnc_babelSetSpeakingLanguage"}
        && {!isNil "acre_api_fnc_babelSetSpokenLanguages"}
        && {!isNil "acre_sys_core_fnc_getSpokenLanguages"};

    if (!_valid) exitWith { [false, false, true] call ACME_fnc_acreBabbleSet; };
    if (uiNamespace getVariable ["ACME_acre_babbleActive", false]) exitWith {};

    private _known = call acre_sys_core_fnc_getSpokenLanguages;
    if !(_known isEqualType []) then {_known = [];};
    private _realKnown = _known - [_id];

    // Never enter a pulse unless there is a guaranteed language to restore. In a module-less mission this is
    // ACME_Common, created by fn_acreBabbleInit. In a mission with Babel, it is the mission's own language set.
    if (_realKnown isEqualTo []) exitWith {
        missionNamespace setVariable ["ACME_acre_babbleReady", false];
        missionNamespace setVariable ["ACME_acre_babbleSafe", false];
        [false, false, true] call ACME_fnc_acreBabbleSet;
    };

    private _current = call _fnCurrentKey;
    if (_current isEqualTo "" || {_current isEqualTo _id} || {!(_current in _realKnown)}) then {
        _current = missionNamespace getVariable ["ACME_acre_baselineLanguage", ""];
        if (_current isEqualTo "" || {!(_current in _realKnown)}) then {_current = _realKnown select 0;};
    };

    missionNamespace setVariable ["ACME_acre_prevKnown", +_realKnown];
    missionNamespace setVariable ["ACME_acre_prevLanguage", _current];

    // Add the synthetic language to the local player's speakable list only for the pulse. ACRE's setter selects the
    // first real language as a side effect, then the next call deliberately selects ACME_Obtunded.
    private _pulseKnown = +_realKnown;
    _pulseKnown pushBackUnique _id;
    [_pulseKnown] call acre_api_fnc_babelSetSpokenLanguages;
    private _ok = [_id] call acre_api_fnc_babelSetSpeakingLanguage;
    if !(_ok isEqualType true && {_ok}) exitWith {
        [false, false, true] call ACME_fnc_acreBabbleSet;
    };
    uiNamespace setVariable ["ACME_acre_babbleActive", true];
} else {
    // RESTORE IS NEVER GATED by the obtundation master. Turning the feature OFF while a pulse is active
    // is exactly when cleanup must still be authorized.
    private _active = uiNamespace getVariable ["ACME_acre_babbleActive", false];
    private _havePrevLanguage = !(isNil {missionNamespace getVariable "ACME_acre_prevLanguage"});
    private _havePrevKnown = !(isNil {missionNamespace getVariable "ACME_acre_prevKnown"});

    if (!_forceRestore && {!_active} && {!_havePrevLanguage} && {!_havePrevKnown}) exitWith {};

    if (_present
        && {!isNil "acre_api_fnc_babelSetSpokenLanguages"}
        && {!isNil "acre_api_fnc_babelSetSpeakingLanguage"}
        && {!isNil "acre_sys_core_fnc_getSpokenLanguages"}) then {

        private _restoreKnown = missionNamespace getVariable ["ACME_acre_prevKnown",
            missionNamespace getVariable ["ACME_acre_baselineKnown", []]];
        if !(_restoreKnown isEqualType []) then {_restoreKnown = [];};
        _restoreKnown = _restoreKnown - [_id];

        private _prev = missionNamespace getVariable ["ACME_acre_prevLanguage",
            missionNamespace getVariable ["ACME_acre_baselineLanguage", ""]];

        private _knownNow = call acre_sys_core_fnc_getSpokenLanguages;
        if !(_knownNow isEqualType []) then {_knownNow = [];};
        private _realKnownNow = _knownNow - [_id];
        if (_restoreKnown isEqualTo [] && {_realKnownNow isNotEqualTo []}) then {
            _restoreKnown = +_realKnownNow;
        };

        private _languages = missionNamespace getVariable ["acre_sys_core_languages", []];
        if !(_languages isEqualType []) then {_languages = [];};
        private _keys = _languages apply {_x param [0, ""]};
        private _realRegistry = _keys - [_id, _common];

        // Stale-state recovery for old ACME builds in a mission with no Babel setup. If ACME_Obtunded is the only
        // usable language, create ACME_Common now and move the player onto it. This is what makes a common-language
        // ACRE module unnecessary for preventing permanent Babel.
        if (_restoreKnown isEqualTo [] && {_realRegistry isEqualTo []} && {_id in _keys}) then {
            if !(_common in _keys) then {
                [_common, "Common"] call acre_api_fnc_babelAddLanguageType;
            };
            _restoreKnown = [_common];
            _prev = _common;
            missionNamespace setVariable ["ACME_acre_baselineKnown", [_common]];
            missionNamespace setVariable ["ACME_acre_baselineLanguage", _common];
            missionNamespace setVariable ["ACME_acre_ownsFallbackCommon", true];
        };

        if (_restoreKnown isNotEqualTo []) then {
            [_restoreKnown] call acre_api_fnc_babelSetSpokenLanguages;
            if (_prev isEqualTo "" || {!(_prev in _restoreKnown)}) then {_prev = _restoreKnown select 0;};
            [_prev] call acre_api_fnc_babelSetSpeakingLanguage;
        };
    };

    uiNamespace setVariable ["ACME_acre_babbleActive", false];
    missionNamespace setVariable ["ACME_acre_prevLanguage", nil];
    missionNamespace setVariable ["ACME_acre_prevKnown", nil];
};
