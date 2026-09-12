/*
    Phase 78: authoritative writer for the per-family medication-toxicity generation latch.
    Modes: mark (family/generation), set (replace from HashMap), clear (remove persisted map).
    Returns the committed map so a caller processing several families can keep a current snapshot.
*/
params [
    ["_patient", objNull, [objNull]],
    ["_mode", "mark", [""]],
    ["_family", "", [""]],
    ["_generation", -1, [0]],
    ["_replacement", createHashMap, [createHashMap]],
    ["_public", true, [false]]
];
if (isNull _patient) exitWith {createHashMap};
if (_mode isEqualTo "clear") exitWith {
    _patient setVariable ["ACME_medicationToxicityFired", nil, _public];
    createHashMap
};
private _copyMap = {
    params ["_src"];
    createHashMapFromArray ((keys _src) apply {[_x, _src get _x]})
};
private _map = if (_mode isEqualTo "set") then {[_replacement] call _copyMap} else {[(_patient getVariable ["ACME_medicationToxicityFired", createHashMap])] call _copyMap};
if (_mode isEqualTo "mark" && {_family != ""}) then {_map set [_family, _generation];};
_patient setVariable ["ACME_medicationToxicityFired", _map, _public];
_map
