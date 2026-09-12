/* Phase 69: authoritative writer for ACME_hypo_temp. */
params [
    ["_patient", objNull, [objNull]],
    ["_temperature", 37, [0]],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]],
    ["_clear", false, [true]]
];
if (isNull _patient) exitWith {_temperature};
if (_clear) exitWith {
    _patient setVariable ["ACME_hypo_temp", nil, _public];
    37
};
if (_public && {_deduplicate}) then {
    [_patient, "ACME_hypo_temp", _temperature] call ACME_fnc_setVarNet;
} else {
    _patient setVariable ["ACME_hypo_temp", _temperature, _public];
};
_temperature
