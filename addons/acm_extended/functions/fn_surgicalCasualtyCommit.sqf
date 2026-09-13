/* Phase 90: authoritative writer for the durable surgical-casualty flag. */
params [["_patient", objNull, [objNull]], ["_value", false, [false]]];
if (isNull _patient) exitWith {};
_patient setVariable ["ACME_surgicalCasualty", _value, true];
