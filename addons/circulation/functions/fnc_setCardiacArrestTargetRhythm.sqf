#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Authoritative circulation-owned writer for the native cardiac-arrest target rhythm.
 *
 * Extended rhythm/toxicity systems request a target through this API instead of writing ACM state directly.
 * Public owner-local writes retain scalar publication deduplication so the rhythm-threshold PFH does not
 * rebroadcast an unchanged target every tick. A change of network owner invalidates the publication cache.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Target rhythm <NUMBER>
 * 2: Public <BOOL> (default true)
 *
 * Return Value:
 * Target rhythm <NUMBER>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_rhythm", 0, [0]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {_rhythm};

if (_public && {local _patient}) then {
    private _ownerStamp = [owner _patient, local _patient];
    private _ownerKey = QGVAR(CardiacArrest_TargetRhythm_ForkPublishOwner);
    private _publishedKey = QGVAR(CardiacArrest_TargetRhythm_ForkPublished);
    if !((_patient getVariable [_ownerKey, []]) isEqualTo _ownerStamp) then {
        _patient setVariable [_ownerKey, _ownerStamp, false];
        _patient setVariable [_publishedKey, -99999, false];
    };
    private _old = _patient getVariable [QGVAR(CardiacArrest_TargetRhythm), -99999];
    private _published = _patient getVariable [_publishedKey, -99999];
    if (_old isEqualTo _rhythm && {_published isEqualTo _rhythm}) exitWith {_rhythm};
    _patient setVariable [_publishedKey, _rhythm, false];
};

_patient setVariable [QGVAR(CardiacArrest_TargetRhythm), _rhythm, _public];
_rhythm
