/*
    Phase 74: authoritative writer for the latched awake-paralysis awareness outcome.
    Numeric/bool values write a field, "KEEP" preserves it, and "CLEAR" removes it.
*/
params [
    ["_patient", objNull],
    ["_event", "KEEP"],
    ["_eventAt", "KEEP"],
    ["_seconds", "KEEP"],
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
["ACME_roc_awarenessEvent", _event] call _write;
["ACME_roc_awarenessAt", _eventAt] call _write;
["ACME_roc_awarenessSeconds", _seconds] call _write;
