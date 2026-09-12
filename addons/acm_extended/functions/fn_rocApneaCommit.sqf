/* Phase 76: authoritative writer for the rocuronium respiratory-muscle apnea flag. */
params [
    ["_patient", objNull, [objNull]],
    ["_apnea", false, [false]],
    ["_public", true, [false]],
    ["_dedupe", true, [false]],
    ["_clear", false, [false]]
];
if (isNull _patient) exitWith {};
if (_dedupe) exitWith {
    if (_clear) then {[_patient, "ACME_roc_apnea", nil] call ACME_fnc_setVarNet;} else {[_patient, "ACME_roc_apnea", _apnea] call ACME_fnc_setVarNet;};
};
if (_clear) then {_patient setVariable ["ACME_roc_apnea", nil, _public];} else {_patient setVariable ["ACME_roc_apnea", _apnea, _public];};
