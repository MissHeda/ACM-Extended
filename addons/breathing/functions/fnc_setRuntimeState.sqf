#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Breathing-owned mutation endpoint for native ACM breathing state touched by Extended systems.
 *
 * The public scalar path retains owner-local publication deduplication. Arrays and object values are forwarded on
 * every request, matching the previous Extended network helper semantics. Unknown field names are ignored.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Changes <ARRAY> of [field,value]
 * 2: Public <BOOL> (default true)
 *
 * Return Value:
 * Number of accepted fields <NUMBER>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_changes", [], [[]]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {0};

private _ownerKey = QGVAR(ForkStatePublishOwner);
private _cacheKey = QGVAR(ForkStatePublished);
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
    params ["_var", "_value", ["_clear", false]];
    if (_clear) exitWith {
        _cache deleteAt (toLowerANSI _var);
        _patient setVariable [_var, nil, _public];
        true
    };

    private _scalar = (typeName _value) in ["SCALAR", "BOOL", "STRING"];
    if (_public && {_scalar} && {local _patient}) then {
        private _k = toLowerANSI _var;
        private _old = _patient getVariable _var;
        private _published = _cache get _k;
        if (!isNil "_old" && {!isNil "_published"} && {_old isEqualTo _value} && {_published isEqualTo _value}) exitWith {false};
        _cache set [_k, _value];
    } else {
        _cache deleteAt (toLowerANSI _var);
    };
    _patient setVariable [_var, _value, _public];
    true
};

private _applied = 0;
{
    if (_x isEqualType [] && {count _x >= 1}) then {
        private _field = _x param [0, "", [""]];
        private _value = _x param [1, 0];
        private _accepted = false;
        switch (_field) do {
            case "respirationRate": { _accepted = [QGVAR(RespirationRate), _value] call _publish; };
            case "bvmProvider": { _accepted = [QGVAR(BVM_provider), _value] call _publish; };
            case "bvmConnectedOxygen": { _accepted = [QGVAR(BVM_ConnectedOxygen), _value] call _publish; };
            case "bvmLastBreath": { _accepted = [QGVAR(BVM_lastBreath), _value] call _publish; };
            case "bvmLastBreathOxygen": { _accepted = [QGVAR(BVM_lastBreathOxygen), _value] call _publish; };
            case "thoracostomyUsedKit": { _accepted = [QGVAR(Thoracostomy_UsedKit), _value] call _publish; };
            case "hemothoraxFluid": { _accepted = [QGVAR(Hemothorax_Fluid), _value] call _publish; };
            case "chestSeal": { _accepted = [QGVAR(ChestSeal_State), _value] call _publish; };
            case "pneumothoraxPFH": { _accepted = [QGVAR(Pneumothorax_PFH), _value] call _publish; };
            case "stethoscopeLungState": { _accepted = [QGVAR(Stethoscope_LungState), _value] call _publish; };
            case "pneumothorax": { _accepted = [QGVAR(Pneumothorax_State), _value] call _publish; };
            case "tensionPneumothorax": { _accepted = [QGVAR(TensionPneumothorax_State), _value] call _publish; };
            case "tensionTime": { _accepted = [QGVAR(TensionPneumothorax_Time), _value] call _publish; };
            case "clearTensionTime": { _accepted = [QGVAR(TensionPneumothorax_Time), 0, true] call _publish; };
            case "hardcorePneumothorax": { _accepted = [QGVAR(Hardcore_Pneumothorax), _value] call _publish; };
            case "hemothorax": { _accepted = [QGVAR(Hemothorax_State), _value] call _publish; };
        };
        if (_accepted) then {_applied = _applied + 1;};
    };
} forEach _changes;
_applied
