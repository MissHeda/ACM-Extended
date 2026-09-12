/*
 * Phase 68: authoritative writer for patient-level blood thermal presentation state.
 *
 * This preserves the existing model exactly: warmed/cold are still patient-level flags and callers may update only
 * the fields they historically touched. objNull means "leave unchanged". _clearTimes removes only the persisted
 * cold/hold clocks; it deliberately does not reinterpret the warmed/cold flags during this ownership-only phase.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_warmed", objNull],
    ["_cold", objNull],
    ["_coldHungAt", objNull],
    ["_holdUntil", objNull],
    ["_public", true, [true]],
    ["_clearTimes", false, [true]]
];
if (isNull _patient) exitWith {false};
if (_warmed isEqualType true) then {_patient setVariable ["ACME_warmedBlood", _warmed, _public];};
if (_cold isEqualType true) then {_patient setVariable ["ACME_coldBlood", _cold, _public];};
if (_clearTimes) then {
    _patient setVariable ["ACME_coldBloodHungAt", nil, _public];
    _patient setVariable ["ACME_tempFlagHoldUntil", nil, _public];
} else {
    if (_coldHungAt isEqualType 0) then {_patient setVariable ["ACME_coldBloodHungAt", _coldHungAt, _public];};
    if (_holdUntil isEqualType 0) then {_patient setVariable ["ACME_tempFlagHoldUntil", _holdUntil, _public];};
};
true
