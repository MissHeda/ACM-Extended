#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Core-owned mutation endpoint for native ACM target vitals.
 *
 * Public scalar writes retain owner-local publication deduplication so high-frequency ventilator/altitude paths do
 * not rebroadcast an unchanged target. A locality/owner change invalidates the publication cache.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Changes <ARRAY> of [field,value]
 *    Supported fields: heartRate, respirationRate, oxygenSaturation
 * 2: Public <BOOL> (default true)
 *
 * Return Value:
 * Number of accepted publications <NUMBER>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_changes", [], [[]]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {0};

private _ownerKey = QGVAR(TargetVitals_ForkPublishOwner);
private _cacheKey = QGVAR(TargetVitals_ForkPublished);
private _cache = _patient getVariable [_cacheKey, createHashMap];
if (_public && {local _patient}) then {
    private _ownerStamp = [owner _patient, local _patient];
    if !((_patient getVariable [_ownerKey, []]) isEqualTo _ownerStamp) then {
        _cache = createHashMap;
        _patient setVariable [_cacheKey, _cache, false];
        _patient setVariable [_ownerKey, _ownerStamp, false];
    };
};

private _publish = {
    params ["_var", "_value"];
    if (_public && {local _patient}) then {
        private _k = toLowerANSI _var;
        private _old = _patient getVariable _var;
        private _published = _cache get _k;
        if (!isNil "_old" && {!isNil "_published"} && {_old isEqualTo _value} && {_published isEqualTo _value}) exitWith {false};
        _cache set [_k, _value];
    };
    _patient setVariable [_var, _value, _public];
    true
};

private _applied = 0;
{
    if (_x isEqualType [] && {count _x >= 2}) then {
        _x params ["_field", "_value"];
        private _accepted = false;
        switch (_field) do {
            case "heartRate": { _accepted = [QGVAR(TargetVitals_HeartRate), _value] call _publish; };
            case "respirationRate": { _accepted = [QGVAR(TargetVitals_RespirationRate), _value] call _publish; };
            case "oxygenSaturation": { _accepted = [QGVAR(TargetVitals_OxygenSaturation), _value] call _publish; };
        };
        if (_accepted) then {_applied = _applied + 1;};
    };
} forEach _changes;
_applied
