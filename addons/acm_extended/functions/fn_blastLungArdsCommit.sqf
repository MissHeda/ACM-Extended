/*
 * Phase 63: authoritative writer for the blast-lung ARDS latch and its pre-latch dwell clock.
 * Pass a non-BOOL for _ards or a non-SCALAR for _clock to leave that field unchanged.
 * _clear is the hard-reset path and removes both fields together.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_ards", objNull],
    ["_clock", objNull],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]],
    ["_clear", false, [true]]
];
if (isNull _patient) exitWith {false};
if (_clear) exitWith {
    _patient setVariable ["ACME_blastLung_ARDS", nil, _public];
    _patient setVariable ["ACME_blastLung_ardsClock", nil, _public];
    false
};
private _write = {
    params ["_name", "_value"];
    if (_public && {_deduplicate}) then {
        [_patient, _name, _value] call ACME_fnc_setVarNet;
    } else {
        _patient setVariable [_name, _value, _public];
    };
};
if (_ards isEqualType true) then {["ACME_blastLung_ARDS", _ards] call _write;};
if (_clock isEqualType 0) then {["ACME_blastLung_ardsClock", _clock] call _write;};
_patient getVariable ["ACME_blastLung_ARDS", false]
