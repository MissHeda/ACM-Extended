/* Phase 71: authoritative writer for the native rhythm post-shock/ROSC grace clock. */
params [
    ["_patient", objNull, [objNull]],
    ["_until", 0, [0]],
    ["_public", false, [false]],
    ["_clear", false, [false]]
];
if (isNull _patient) exitWith {};
if (_clear) then {
    _patient setVariable ["ACME_rhythmNativeShockGraceUntil", nil, _public];
} else {
    _patient setVariable ["ACME_rhythmNativeShockGraceUntil", _until, _public];
};
