/*
 * Phase 66: authoritative writer for cumulative CaCl2-equivalent calcium credit.
 * Modes: "add" performs the owner-local read/modify/write transaction, "set" restores an absolute value,
 * and "clear" removes the field at a clinical reset boundary.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_value", 0, [0]],
    ["_mode", "add", [""]],
    ["_public", true, [true]],
    ["_deduplicate", false, [true]]
];
if (isNull _patient) exitWith {0};
private _modeL = toLowerANSI _mode;
if (_modeL isEqualTo "clear") exitWith {
    _patient setVariable ["ACME_ca_caCl2Given", nil, _public];
    0
};
private _new = switch (_modeL) do {
    case "set": {_value max 0};
    default {((_patient getVariable ["ACME_ca_caCl2Given", 0]) + _value) max 0};
};
if (_public && {_deduplicate}) then {
    [_patient, "ACME_ca_caCl2Given", _new] call ACME_fnc_setVarNet;
} else {
    _patient setVariable ["ACME_ca_caCl2Given", _new, _public];
};
_new
