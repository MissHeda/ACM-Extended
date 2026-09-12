#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * CBRN-owned writer for the native breathing-ability state.
 *
 * Public owner-local writes retain a publication cache because blast-lung integration may request the same value
 * repeatedly between native CBRN exposure updates.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_ability", 1, [0]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {_ability};

if (_public && {local _patient}) then {
    private _ownerKey = QGVAR(BreathingAbility_ForkPublishOwner);
    private _publishedKey = QGVAR(BreathingAbility_ForkPublished);
    private _ownerStamp = [owner _patient, local _patient];
    if !((_patient getVariable [_ownerKey, []]) isEqualTo _ownerStamp) then {
        _patient setVariable [_ownerKey, _ownerStamp, false];
        _patient setVariable [_publishedKey, -99999, false];
    };
    private _old = _patient getVariable [QGVAR(BreathingAbility_State), -99999];
    private _published = _patient getVariable [_publishedKey, -99999];
    if (_old isEqualTo _ability && {_published isEqualTo _ability}) exitWith {_ability};
    _patient setVariable [_publishedKey, _ability, false];
};

_patient setVariable [QGVAR(BreathingAbility_State), _ability, _public];
_ability
