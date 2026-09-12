/*
 * Phase 61: authoritative writer for the native-rhythm persistence latch pair.
 * Hold kind and held rhythm describe one latch. An empty kind always means no held rhythm.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_kind", "", [""]],
    ["_rhythm", -1, [0]],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]]
];
if (isNull _patient) exitWith {[_kind, _rhythm]};
if (_kind isEqualTo "") then {_rhythm = -1;};
if (_public && {_deduplicate}) then {
    [_patient, "ACME_rhythmNativeHoldKind", _kind] call ACME_fnc_setVarNet;
    [_patient, "ACME_rhythmNativeHoldRhythm", _rhythm] call ACME_fnc_setVarNet;
} else {
    _patient setVariable ["ACME_rhythmNativeHoldKind", _kind, _public];
    _patient setVariable ["ACME_rhythmNativeHoldRhythm", _rhythm, _public];
};
[_kind, _rhythm]
