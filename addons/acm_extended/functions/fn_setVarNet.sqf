// Network audit candidate NA1. Exact scalar deduplication; no physiology quantization.
// Usage: [_object, _variableName, _value] call ACME_fnc_setVarNet.
// Mutable arrays/HashMaps are ALWAYS forwarded: callers mutate them by reference.
// A local scalar value alone is not proof it has ever been published. Keep an
// independent, object-local cache of the last value this helper published.
// Only the object's current owner may suppress. Non-owner writes pass through.
// Counters measure helper calls, NOT packets, bytes, delivery or acknowledgement.
params [["_obj", objNull, [objNull]], ["_name", "", [""]], "_value"];
if (isNull _obj || {_name isEqualTo ""}) exitWith {};

private _counting = missionNamespace getVariable ["ACME_net_count", false];
if (_counting && {isNil "ACME_net_since"}) then { ACME_net_since = diag_tickTime; };
private _hasValue = !isNil "_value";
private _isScalar = false;
if (_hasValue) then { _isScalar = (typeName _value) in ["SCALAR", "BOOL", "STRING"]; };
private _cacheKey = toLowerANSI _name;
private _cache = _obj getVariable ["ACME_net_scalarCache", createHashMap];
private _ownerStamp = [owner _obj, local _obj];
if !((_obj getVariable ["ACME_net_cacheOwner", []]) isEqualTo _ownerStamp) then {
    _cache = createHashMap;
    _obj setVariable ["ACME_net_scalarCache", _cache];
    _obj setVariable ["ACME_net_cacheOwner", _ownerStamp];
};

private _same = false;
if (_isScalar && {local _obj}) then {
    private _old = _obj getVariable _name;
    private _published = _cache get _cacheKey;
    _same = !isNil "_old" && {!isNil "_published"}
        && {_old isEqualTo _value} && {_published isEqualTo _value};
};
// This exit MUST be at function scope, not inside a nested 'then' block.
if (_same) exitWith {
    if (_counting) then {
        private _m = missionNamespace getVariable ["ACME_net_saved", createHashMap];
        _m set [_name, (_m getOrDefault [_name, 0]) + 1];
        missionNamespace setVariable ["ACME_net_saved", _m];
    };
};

if (_counting) then {
    private _m = missionNamespace getVariable ["ACME_net_sent", createHashMap];
    _m set [_name, (_m getOrDefault [_name, 0]) + 1];
    missionNamespace setVariable ["ACME_net_sent", _m];
};
if (_isScalar && {local _obj}) then {
    _cache set [_cacheKey, _value];
} else {
    _cache deleteAt _cacheKey;
};
if (!_hasValue) exitWith { _obj setVariable [_name, nil, true]; };
_obj setVariable [_name, _value, true];
