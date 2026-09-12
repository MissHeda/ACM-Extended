/*
    Phase 73: authoritative mutation boundary for the acute awake-paralysis stress state.
    Numeric values write a field, "KEEP" leaves it unchanged, and "CLEAR" removes it.
    _dedupe preserves the former live-tick setVarNet publication contract.
*/
params [
    ["_patient", objNull],
    ["_postROSCGraceUntil", "KEEP"],
    ["_awakeDwell", "KEEP"],
    ["_awakeResistAdd", "KEEP"],
    ["_hrDrive", "KEEP"],
    ["_public", true],
    ["_dedupe", false]
];
if (isNull _patient) exitWith {};
private _write = {
    params ["_name", "_value"];
    if (_value isEqualType "") exitWith {
        if (_value isEqualTo "CLEAR") then {
            if (_dedupe) then {[_patient, _name, nil] call ACME_fnc_setVarNet;} else {_patient setVariable [_name, nil, _public];};
        };
    };
    if (_dedupe) then {[_patient, _name, _value] call ACME_fnc_setVarNet;} else {_patient setVariable [_name, _value, _public];};
};
["ACME_roc_postROSCGraceUntil", _postROSCGraceUntil] call _write;
["ACME_roc_awakeDwell", _awakeDwell] call _write;
["ACME_roc_awakeResistAdd", _awakeResistAdd] call _write;
["ACME_hrDrive_roc", _hrDrive] call _write;
