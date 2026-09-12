/* v1.1.0 provider-animation weapon preflight.
 * Select empty hands at most once for an animation episode and return the short settle delay the caller should
 * respect before starting its authored RTM. A second ACME owner arriving while that first holster is still
 * entering must wait on it, never issue another put-away animation. Weapons are never automatically restored.
 */
params [["_medic", objNull, [objNull]]];
if (isNull _medic || {!local _medic} || {!alive _medic} || {[_medic] call ACME_fnc_animBlocked}) exitWith {0};
if (currentWeapon _medic == "") exitWith {0};

private _previous = _medic getVariable ["ACME_medicAnimationPrep", []];
if (_previous isEqualType [] && {count _previous >= 2} && {(_previous param [0, ""]) == "empty_hands_once"}) then {
    private _elapsed = CBA_missionTime - (_previous param [1, -99]);
    // The request is still settling. Do not replay the holster animation just because currentWeapon has not cleared
    // on this exact frame yet.
    if (_elapsed >= 0 && {_elapsed < 1.10}) exitWith {(1.10 - _elapsed) max 0.05};
};

if (!isNil "ace_weaponselect_fnc_putWeaponAway") then {
    [_medic] call ace_weaponselect_fnc_putWeaponAway;
} else {
    _medic action ["SwitchWeapon", _medic, _medic, 299];
};
_medic setVariable ["ACME_medicAnimationPrep", ["empty_hands_once", CBA_missionTime], false];
0.70
