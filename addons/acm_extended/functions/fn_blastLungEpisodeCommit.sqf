/*
    Phase 77: authoritative writer for blast-lung episode metadata.
    Numeric values write, "KEEP" preserves, and "CLEAR" removes a field.
*/
params [
    ["_patient", objNull],
    ["_exposures", "KEEP"],
    ["_onset", "KEEP"],
    ["_lastInjury", "KEEP"],
    ["_public", true]
];
if (isNull _patient) exitWith {};
private _write = {
    params ["_name", "_value"];
    if (_value isEqualType "") exitWith {if (_value isEqualTo "CLEAR") then {_patient setVariable [_name, nil, _public];};};
    _patient setVariable [_name, _value, _public];
};
["ACME_blastLung_exposures", _exposures] call _write;
["ACME_blastLung_Onset", _onset] call _write;
["ACME_blastLung_Time", _lastInjury] call _write;
