/* Authoritative mutation gate for the Extended circulation physiology HashMap. */
params [
    ["_patient", objNull, [objNull]],
    ["_state", createHashMap, [createHashMap]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {false};
_patient setVariable ["ACME_circ_State", _state, _public];
true
