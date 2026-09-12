// a best-effort radio and voice mute for the obtunded state. it runs locally on the machine of the affected
// player, which is where acre and tfar want voice calls made.
// neither mod exposes a single clean mute-my-mic call, and the exact api differs by version, so every call here is
// guarded with isnil and every setvariable is harmless if the mod is not loaded. if a lever below is wrong for
// your build it simply no-ops rather than erroring. verify against your radio mod and version and tweak this one
// file.
// _this is [_unit, _mute], where a _mute of true silences and false restores.
params ["_unit", ["_mute", true]];

// TFAR mute handling is retained separately from ACRE babble.  Manual/debug obtundation may still exercise this
// legacy TFAR path, but B65's ACRE babble scheduler below has no manual bypass: it requires the master option ON.
private _effectiveMute = _mute
    && {(missionNamespace getVariable ["ACME_sys_obtunded", false]) || {_unit getVariable ["ACME_obtunded_manual", false]}}
    && {!isNull _unit}
    && {alive _unit}
    && {_unit getVariable ["ACME_obtunded", false]}
    && {!(_unit getVariable ["ACE_isUnconscious", false])};

// tfar, the beta "TFAR_fnc_*" api.
_unit setVariable ["tf_unable_to_use_radio", _effectiveMute, true];
_unit setVariable ["tf_voiceVolume", ([1, 0] select _effectiveMute), true];
if (!isNil "TFAR_fnc_setForbiddenToSpeak") then {
    [_unit, _effectiveMute] call TFAR_fnc_setForbiddenToSpeak;
};

// tfar, the legacy "task_force_radio" api.
_unit setVariable ["tf_unconscious_analog_radio", _effectiveMute, true];

// ACRE2.
// B65 deliberately does NOT enable babble here.  Voice state transitions happen for the whole obtunded episode,
// while babble is only allowed in brief speech-aware windows owned by fn_acreBabbleTick.  A restore request is
// still safe here so lucid/recovery transitions can terminate a pulse immediately.
if (_unit isEqualTo player && {!_effectiveMute}) then {
    [false] call ACME_fnc_acreBabbleSet;
};
