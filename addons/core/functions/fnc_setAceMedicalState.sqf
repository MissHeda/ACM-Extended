#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * ACM core-owned integration boundary for ACE medical patient state that has no public ACE setter with equivalent
 * semantics. ACE remains the canonical storage owner; Extended callers request changes through this bridge instead
 * of publishing ace_medical_* variables directly.
 *
 * Each change is [field, value, public, deduplicate]. If value is omitted, the variable is cleared (nil).
 * Public defaults false. Deduplicate defaults false and exactly mirrors the former ACME_fnc_setVarNet scalar rule:
 * only the current object owner may suppress a scalar already published by this bridge. Arrays/HashMaps/objects are
 * always forwarded.
 *
 * Supported fields:
 * allowUnconParam, bandagedWounds, bloodVolume, bodyTemperature, instantDeathImmune, deathBlocked,
 * soundTimeoutMoan, lastWakeUpCheck, medications, occludedMedications, openWounds, pain, spo2,
 * aiUnconsciousness, cardiacArrestTimeLeft, stitchedWounds, treatmentEndInAnim.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_changes", [], [[]]]
];
if (isNull _patient) exitWith {0};

private _resolve = {
    params ["_field"];
    switch (_field) do {
        case "allowUnconParam": {"ace_medical_allowUnconParam"};
        case "bandagedWounds": {"ace_medical_bandagedWounds"};
        case "bloodVolume": {"ace_medical_bloodVolume"};
        case "bodyTemperature": {"ace_medical_bodyTemperature"};
        case "instantDeathImmune": {"ace_medical_damage_InstantDeathImmune"};
        case "deathBlocked": {"ace_medical_deathBlocked"};
        case "soundTimeoutMoan": {"ace_medical_feedback_soundTimeoutmoan"};
        case "lastWakeUpCheck": {"ace_medical_lastWakeUpCheck"};
        case "medications": {"ace_medical_medications"};
        case "occludedMedications": {"ace_medical_occludedMedications"};
        case "openWounds": {"ace_medical_openWounds"};
        case "pain": {"ace_medical_pain"};
        case "spo2": {"ace_medical_spo2"};
        case "aiUnconsciousness": {"ace_medical_statemachine_AIUnconsciousness"};
        case "cardiacArrestTimeLeft": {"ace_medical_statemachine_cardiacArrestTimeLeft"};
        case "stitchedWounds": {"ace_medical_stitchedWounds"};
        case "treatmentEndInAnim": {"ace_medical_treatment_endInAnim"};
        default {""};
    }
};

private _ownerKey = QGVAR(ACEState_ForkPublishOwner);
private _cacheKey = QGVAR(ACEState_ForkPublished);
private _cache = _patient getVariable [_cacheKey, createHashMap];
private _ownerStamp = [owner _patient, local _patient];
if !((_patient getVariable [_ownerKey, []]) isEqualTo _ownerStamp) then {
    _cache = createHashMap;
    _patient setVariable [_cacheKey, _cache, false];
    _patient setVariable [_ownerKey, _ownerStamp, false];
};

private _applied = 0;
{
    if (_x isEqualType [] && {count _x >= 1}) then {
        private _field = _x param [0, "", [""]];
        private _var = [_field] call _resolve;
        if (_var isNotEqualTo "") then {
            private _hasValue = count _x >= 2;
            private _public = _x param [2, false, [true]];
            private _deduplicate = _x param [3, false, [true]];
            private _skip = false;

            if (!_hasValue) then {
                _patient setVariable [_var, nil, _public];
                _cache deleteAt (toLowerANSI _var);
                _applied = _applied + 1;
            } else {
                private _value = _x select 1;
                if (_deduplicate && {_public} && {local _patient} && {(typeName _value) in ["SCALAR", "BOOL", "STRING"]}) then {
                    private _k = toLowerANSI _var;
                    private _old = _patient getVariable _var;
                    private _published = _cache get _k;
                    _skip = !isNil "_old" && {!isNil "_published"} && {_old isEqualTo _value} && {_published isEqualTo _value};
                    if (!_skip) then {_cache set [_k, _value];};
                } else {
                    _cache deleteAt (toLowerANSI _var);
                };
                if (!_skip) then {
                    _patient setVariable [_var, _value, _public];
                    _applied = _applied + 1;
                };
            };
        };
    };
} forEach _changes;
_applied
