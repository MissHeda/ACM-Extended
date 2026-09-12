/* Phase 65: authoritative writer for the active rocuronium paralysis flag. */
params [
    ["_patient", objNull, [objNull]],
    ["_paralyzed", false, [true]],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]]
];
if (isNull _patient) exitWith {_paralyzed};
if (_public && {_deduplicate}) then {
    [_patient, "ACME_roc_paralyzed", _paralyzed] call ACME_fnc_setVarNet;
} else {
    _patient setVariable ["ACME_roc_paralyzed", _paralyzed, _public];
};
_paralyzed
