// B65: ACRE2 obtunded-babble language switch.
//
// HARD INVARIANT:
// ACME may only ENABLE the synthetic babble language from the dedicated pulse scheduler, while the local player
// is alive, awake, actually obtunded, and the mission's Obtundation master option is enabled.  Every other caller
// can still request a restore.  This keeps an interrupted/late/stale call from turning babble into an independent
// ACRE state when obtundation is disabled.
//
// _this = [_on, _pulseAuthorized, _forceRestore]
// _pulseAuthorized is deliberately false by default.  Only fn_acreBabbleTick sends true.
// _forceRestore is used by startup/master-switch sanitation so an old ACME_Obtunded language is scrubbed even if
// this build did not create the state flag that normally tells us a restore is necessary.
params [
    ["_on", true],
    ["_pulseAuthorized", false],
    ["_forceRestore", false]
];
if (!hasInterface) exitWith {};

private _id = missionNamespace getVariable ["ACME_acre_babbleId", "ACME_Obtunded"];
private _player = if (!isNil "ACE_player" && {!isNull ACE_player}) then {ACE_player} else {player};

if (_on) then {
    private _valid = _pulseAuthorized
        && {missionNamespace getVariable ["ACME_sys_obtunded", false]}
        && {missionNamespace getVariable ["ACME_acre_babbleEnable", false]}
        && {missionNamespace getVariable ["ACME_acre_present", false]}
        && {!isNull _player}
        && {alive _player}
        && {_player getVariable ["ACME_obtunded", false]}
        && {!(_player getVariable ["ACE_isUnconscious", false])}
        && {!(uiNamespace getVariable ["ACME_obtunded_lucidActive", false])}
        && {!isNil "acre_api_fnc_isSpeaking"}
        && {[_player] call acre_api_fnc_isSpeaking}
        && {!isNil "acre_api_fnc_babelSetSpeakingLanguage"};

    // A rejected enable becomes a cleanup request.  Force it so a stale ACRE language from an older/interrupted
    // build cannot survive merely because this build never set ACME_acre_babbleActive.
    if (!_valid) exitWith { [false, false, true] call ACME_fnc_acreBabbleSet; };

    // Do not hammer ACRE's language API for every scheduler tick inside one short pulse.
    if (uiNamespace getVariable ["ACME_acre_babbleActive", false]) exitWith {};

    if (isNil "acre_api_fnc_babelGetSpeakingLanguageId") exitWith {};
    private _cur = call acre_api_fnc_babelGetSpeakingLanguageId;
    if (!isNil "_cur" && {_cur isEqualType ""} && {_cur isNotEqualTo _id}) then {
        missionNamespace setVariable ["ACME_acre_prevLanguage", _cur];
    };

    // ACRE only lets a player select a language they can speak.  Temporarily add the synthetic language and save
    // the exact previous speakable-language list so every pulse can restore cleanly.
    if (!isNil "acre_sys_core_fnc_getSpokenLanguages" && {!isNil "acre_api_fnc_babelSetSpokenLanguages"}) then {
        private _known = call acre_sys_core_fnc_getSpokenLanguages;
        if (_known isEqualType [] && {!(_id in _known)}) then {
            missionNamespace setVariable ["ACME_acre_prevKnown", +_known];
            [_known + [_id]] call acre_api_fnc_babelSetSpokenLanguages;
        };
    };

    [_id] call acre_api_fnc_babelSetSpeakingLanguage;
    uiNamespace setVariable ["ACME_acre_babbleActive", true];
} else {
    // RESTORE IS NEVER GATED BY THE OBTUNDATION MASTER OR BABBLE FEATURE FLAG.  Those are exactly the settings
    // that can be switched off while a pulse is active, and cleanup must still be allowed to run afterward.
    private _active = uiNamespace getVariable ["ACME_acre_babbleActive", false];
    private _havePrevLanguage = !(isNil {missionNamespace getVariable "ACME_acre_prevLanguage"});
    private _havePrevKnown = !(isNil {missionNamespace getVariable "ACME_acre_prevKnown"});
    if (!_forceRestore && {!_active} && {!_havePrevLanguage} && {!_havePrevKnown}) exitWith {};

    if (missionNamespace getVariable ["ACME_acre_present", false]) then {
        private _prev = missionNamespace getVariable ["ACME_acre_prevLanguage", ""];
        private _restoreKnown = missionNamespace getVariable ["ACME_acre_prevKnown", []];

        // Recover even if an older/interrupted build lost its saved language variables.  Remove ACME_Obtunded
        // from the currently speakable languages and pick a real language as a best-effort fallback.
        if (!isNil "acre_sys_core_fnc_getSpokenLanguages") then {
            private _knownNow = call acre_sys_core_fnc_getSpokenLanguages;
            if (_knownNow isEqualType []) then {
                private _cleanKnown = _knownNow - [_id];
                if !(_restoreKnown isEqualType [] && {(count _restoreKnown) > 0}) then {
                    _restoreKnown = +_cleanKnown;
                };
                if (_prev == "" && {(count _cleanKnown) > 0}) then {
                    _prev = _cleanKnown select 0;
                };
            };
        };

        if (_restoreKnown isEqualType [] && {(count _restoreKnown) > 0} && {!isNil "acre_api_fnc_babelSetSpokenLanguages"}) then {
            [_restoreKnown] call acre_api_fnc_babelSetSpokenLanguages;
        };
        if (_prev isNotEqualTo "" && {!isNil "acre_api_fnc_babelSetSpeakingLanguage"}) then {
            [_prev] call acre_api_fnc_babelSetSpeakingLanguage;
        };
    };

    uiNamespace setVariable ["ACME_acre_babbleActive", false];
    missionNamespace setVariable ["ACME_acre_prevLanguage", nil];
    missionNamespace setVariable ["ACME_acre_prevKnown", nil];
};
