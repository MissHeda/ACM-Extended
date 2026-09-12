// the master obtundation switch changed. it is the CBA callback on ACME_sys_obtunded.
// call it as [] call ACME_fnc_obtundedMasterChanged.
//
// WHY IT EXISTS.
// the master gates fn_obtundedTick, which is the loop that maintains the posture, holds the input lock and
// evaluates a casualty back out of the state. switching the master off while somebody is obtunded therefore
// stopped the only thing that could ever release them, and left a player awake, down and locked with nothing
// watching. the state had no owner and no exit.
// so the switch releases every obtunded unit on this machine as it goes off. a casualty who is genuinely
// unconscious is handed straight back to ACE and drops where they lie, which is the correct outcome and the same
// one the tick would have produced.
// the on direction does not force a casualty state. B65 only uses it to allow the optional ACRE babble language
// to register once the mission has explicitly enabled Obtundation; physiology still owns who actually enters it.

if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith {
    // If the mission enables obtundation after client startup, this is the point where the optional ACRE language
    // is allowed to register.  Registration never happens while the master remains OFF.
    call ACME_fnc_acreBabbleInit;
};

// B65 safety gate: the instant the master goes OFF, scrub any active/stale ACRE obtunded language before doing
// anything else.  Cleanup is force-authorized even if this client never created the current state flag.
[false, false, true] call ACME_fnc_acreBabbleSet;
uiNamespace setVariable ["ACME_acre_babbleWasSpeaking", false];
uiNamespace setVariable ["ACME_acre_babbleNextPulse", -1];
uiNamespace setVariable ["ACME_acre_babblePulseUntil", -1];

{
    if (local _x && {_x getVariable ["ACME_obtunded", false]}) then {
        // "deteriorate" releases in place with no stand up, so a casualty whose vitals are still bad slumps
        // rather than being stood up and knocked straight down again.
        [_x, false, false, "back", "deteriorate"] call ACME_fnc_obtundedSet;
    };
} forEach allUnits;
