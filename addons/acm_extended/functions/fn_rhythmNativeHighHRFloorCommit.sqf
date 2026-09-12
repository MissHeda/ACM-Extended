/* Phase 71: authoritative writer for the native high-HR persistence floor clock. */
params [
    ["_patient", objNull, [objNull]],
    ["_until", 0, [0]],
    ["_public", false, [false]],
    ["_dedupe", false, [false]],
    ["_clear", false, [false]]
];
if (isNull _patient) exitWith {};
if (_dedupe) exitWith {
    if (_clear) then {
        [_patient, "ACME_rhythmNativeHighHRFloorUntil", nil] call ACME_fnc_setVarNet;
    } else {
        [_patient, "ACME_rhythmNativeHighHRFloorUntil", _until] call ACME_fnc_setVarNet;
    };
};
if (_clear) then {
    _patient setVariable ["ACME_rhythmNativeHighHRFloorUntil", nil, _public];
} else {
    _patient setVariable ["ACME_rhythmNativeHighHRFloorUntil", _until, _public];
};
