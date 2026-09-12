// Phase 59: authoritative writer for the persistent obtundation state tuple.
//
// ACME_obtunded, ACME_obtunded_manual and ACME_obtunded_posture describe one logical state and must not drift
// independently. Transient animation/transition flags remain owned by the local application/transition workers.
// _this: [patient, on, manual, posture, transitionToken, public]
params [
    ["_patient", objNull],
    ["_on", false],
    ["_manual", false],
    ["_posture", "free"],
    ["_token", -1],
    ["_public", true]
];
if (isNull _patient) exitWith {false};

// B49 has exactly one awake-obtunded posture. Keep accepting the posture argument for compatibility with older
// callers/snapshots, but normalize storage at the mutation boundary so no caller can reintroduce a forced pose.
private _storedPosture = if (_on) then {"free"} else {""};
_patient setVariable ["ACME_obtunded", _on, _public];
_patient setVariable ["ACME_obtunded_manual", (_on && _manual), _public];
_patient setVariable ["ACME_obtunded_posture", _storedPosture, _public];
if (_token >= 0) then {
    _patient setVariable ["ACME_obtunded_transitionToken", _token, _public];
};
true
