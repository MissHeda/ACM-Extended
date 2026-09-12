/*
 * Phase 62: authoritative NRB delivery-state writer.
 *
 * ACME_nrb_on, ACME_nrb_hasO2 and ACME_nrb_delivering form one invariant:
 * - mask off => no O2 source attached and no active delivery;
 * - no O2 source => no active delivery.
 *
 * Pass -1 for any bool argument that should retain its current value. Publication mode mirrors the existing
 * direct-vs-setVarNet contracts used by setup/lifecycle code versus the 0.5 s flow worker.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_on", -1],
    ["_hasO2", -1],
    ["_delivering", -1],
    ["_public", true, [true]],
    ["_deduplicate", true, [true]]
];
if (isNull _patient) exitWith {[false, false, false]};

private _curOn = _patient getVariable ["ACME_nrb_on", false];
private _curO2 = _patient getVariable ["ACME_nrb_hasO2", false];
private _curDelivering = _patient getVariable ["ACME_nrb_delivering", false];
private _writeOn = _on isEqualType true;
private _writeO2 = _hasO2 isEqualType true;
private _writeDelivering = _delivering isEqualType true;
private _newOn = if (_writeOn) then {_on} else {_curOn};
private _newO2 = if (_writeO2) then {_hasO2} else {_curO2};
private _newDelivering = if (_writeDelivering) then {_delivering} else {_curDelivering};

// Invariant-driven writes count as explicit writes so stale paired state is repaired at the same transaction.
if (!_newOn) then {
    _newO2 = false;
    _newDelivering = false;
    _writeO2 = true;
    _writeDelivering = true;
};
if (!_newO2) then {
    _newDelivering = false;
    _writeDelivering = true;
};
if (_newDelivering && {!_newOn || {!_newO2}}) then {
    _newDelivering = false;
};

private _publish = {
    params ["_name", "_value"];
    if (_public && {_deduplicate}) then {
        [_patient, _name, _value] call ACME_fnc_setVarNet;
    } else {
        _patient setVariable [_name, _value, _public];
    };
};
if (_writeOn) then {["ACME_nrb_on", _newOn] call _publish;};
if (_writeO2) then {["ACME_nrb_hasO2", _newO2] call _publish;};
if (_writeDelivering) then {["ACME_nrb_delivering", _newDelivering] call _publish;};
[_newOn, _newO2, _newDelivering]
