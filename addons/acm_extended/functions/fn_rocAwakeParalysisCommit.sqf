/* Phase 75: authoritative writer for the derived awake-paralysis flag. */
params [
    ["_patient", objNull, [objNull]],
    ["_awake", false, [false]],
    ["_public", true, [false]],
    ["_dedupe", true, [false]],
    ["_clear", false, [false]]
];
if (isNull _patient) exitWith {};
if (_dedupe) exitWith {
    if (_clear) then {[_patient, "ACME_roc_awakeParalysis", nil] call ACME_fnc_setVarNet;} else {[_patient, "ACME_roc_awakeParalysis", _awake] call ACME_fnc_setVarNet;};
};
if (_clear) then {_patient setVariable ["ACME_roc_awakeParalysis", nil, _public];} else {_patient setVariable ["ACME_roc_awakeParalysis", _awake, _public];};
