/* Phase 72: authoritative writer for the ventilator-derived pulmonary shunt state. */
params [
    ["_patient", objNull, [objNull]],
    ["_shunt", 0, [0]],
    ["_public", true, [false]],
    ["_clear", false, [false]]
];
if (isNull _patient) exitWith {};
if (_clear) then {
    _patient setVariable ["ACME_vent_shunt", nil, _public];
} else {
    _patient setVariable ["ACME_vent_shunt", _shunt, _public];
};
