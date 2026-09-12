/*
 * Phase 70: authoritative writer for ACME_requiresEvac.
 * This phase preserves the existing shared-boolean semantics exactly; it does not introduce per-cause reason tracking.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_required", false, [true]],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]],
    ["_clear", false, [true]]
];
if (isNull _patient) exitWith {false};
if (_clear) exitWith {
    if (_public && {_deduplicate}) then {
        [_patient, "ACME_requiresEvac", nil] call ACME_fnc_setVarNet;
    } else {
        _patient setVariable ["ACME_requiresEvac", nil, _public];
    };
    false
};
if (_public && {_deduplicate}) then {
    [_patient, "ACME_requiresEvac", _required] call ACME_fnc_setVarNet;
} else {
    _patient setVariable ["ACME_requiresEvac", _required, _public];
};
_required
