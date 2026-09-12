// Phase 142: initialize ACME's ACRE2 obtunded speech corruption without requiring an ACRE Babel module.
//
// ACRE starts with no Babel languages, ACRE_CURRENT_LANGUAGE_ID = 0 and ACRE_SPOKEN_LANGUAGES = []. Registering only
// ACME_Obtunded in that state turns index 0 into the synthetic language, so an interrupted restore can leave every
// transmission sounding like Babel until a mission module later supplies a real/common language. ACME now establishes
// a deterministic ACME_Common baseline only when Obtundation is enabled and the mission has no Babel setup of its own.
// If the mission already configured Babel, its language list and the player's exact speaking language are preserved.
// Master OFF never bootstraps Babel; it only asks the restore path to scrub stale ACME-owned state from older builds.
if (!hasInterface) exitWith {};

private _hasAcre = isClass (configFile >> "CfgPatches" >> "acre_main");
missionNamespace setVariable ["ACME_acre_present", _hasAcre];
if (!_hasAcre) exitWith {};

if !(missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith {
    [false, false, true] call ACME_fnc_acreBabbleSet;
};
if !(missionNamespace getVariable ["ACME_acre_babbleEnable", false]) exitWith {};

// Require the exact APIs used by the transaction. If one is missing, babble is disabled rather than partially
// changing ACRE's language state.
if (isNil "acre_api_fnc_babelAddLanguageType"
    || {isNil "acre_api_fnc_babelSetSpokenLanguages"}
    || {isNil "acre_api_fnc_babelSetSpeakingLanguage"}
    || {isNil "acre_api_fnc_babelGetSpeakingLanguageId"}
    || {isNil "acre_sys_core_fnc_getSpokenLanguages"}) exitWith {
    missionNamespace setVariable ["ACME_acre_babbleReady", false];
    missionNamespace setVariable ["ACME_acre_babbleSafe", false];
};

private _id = missionNamespace getVariable ["ACME_acre_babbleId", "ACME_Obtunded"];
private _common = missionNamespace getVariable ["ACME_acre_commonId", "ACME_Common"];
private _languages = missionNamespace getVariable ["acre_sys_core_languages", []];
if !(_languages isEqualType []) then {_languages = [];};

private _languageKeys = _languages apply {_x param [0, ""]};
private _realRegistry = _languageKeys - [_id, _common];
private _known = call acre_sys_core_fnc_getSpokenLanguages;
if !(_known isEqualType []) then {_known = [];};
private _realKnown = _known - [_id];
private _missionKnown = _known - [_id, _common];

// ACRE's documented public getter says STRING, while current ACRE source forwards the internal numeric language
// index. Support both so ACME restores the actual pre-pulse language on both current and future ACRE builds.
private _currentRaw = call acre_api_fnc_babelGetSpeakingLanguageId;
private _current = "";
if (_currentRaw isEqualType "") then {
    _current = _currentRaw;
} else {
    if (_currentRaw isEqualType 0 && {_currentRaw >= 0} && {_currentRaw < count _languages}) then {
        _current = (_languages select _currentRaw) param [0, ""];
    };
};

private _ownsFallback = false;
// If a real mission Babel registry exists, ACME_Common is never allowed to masquerade as a mission assignment.
// This matters when a scripted/module setup arrives after ACME's fallback: every client pauses corruption until
// ACRE has actually assigned one of the mission's real languages. That prevents client-order differences in the
// local numeric language registry from ever becoming audible Babel.
if (_realRegistry isNotEqualTo [] && {_missionKnown isEqualTo []}) exitWith {
    missionNamespace setVariable ["ACME_acre_babbleReady", false];
    missionNamespace setVariable ["ACME_acre_babbleSafe", false];
};
if (_realRegistry isNotEqualTo []) then {
    _realKnown = +_missionKnown;
    if (_common in _known) then {
        // Hand ownership fully back to the mission and remove ACME's fallback from the player's speakable set.
        // babelSetSpokenLanguages selects its first entry as a side effect; _current is restored/normalized below.
        [_realKnown] call acre_api_fnc_babelSetSpokenLanguages;
    };
};

if (_realRegistry isEqualTo [] && {_realKnown isEqualTo []}) then {
    // No mission Babel setup exists. Create a common language locally on every ACME client so normal speech has a
    // guaranteed non-garbled home even without an ACRE module. The synthetic language is added afterward.
    if !(_common in _languageKeys) then {
        [_common, "Common"] call acre_api_fnc_babelAddLanguageType;
        _languages = missionNamespace getVariable ["acre_sys_core_languages", []];
        _languageKeys = _languages apply {_x param [0, ""]};
    };
    [_common] call acre_api_fnc_babelSetSpokenLanguages;
    [_common] call acre_api_fnc_babelSetSpeakingLanguage;
    _realKnown = [_common];
    _current = _common;
    _ownsFallback = true;
};

if (_current isEqualTo "" || {_current isEqualTo _id} || {!(_current in _realKnown)}) then {
    _current = _realKnown select 0;
    [_current] call acre_api_fnc_babelSetSpeakingLanguage;
};

missionNamespace setVariable ["ACME_acre_baselineKnown", +_realKnown];
missionNamespace setVariable ["ACME_acre_baselineLanguage", _current];
missionNamespace setVariable ["ACME_acre_ownsFallbackCommon", _ownsFallback];

// Register the synthetic language only after a real/common restoration target is guaranteed.
if !(_id in _languageKeys) then {
    [_id, "Obtunded"] call acre_api_fnc_babelAddLanguageType;
};

missionNamespace setVariable ["ACME_acre_babbleRegistered", true];
missionNamespace setVariable ["ACME_acre_babbleSafe", true];
missionNamespace setVariable ["ACME_acre_babbleReady", true];

// Normalize any leftover ACME pulse immediately. This restores the exact real language captured above.
[false, false, true] call ACME_fnc_acreBabbleSet;
