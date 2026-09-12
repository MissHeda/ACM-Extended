/* Native NV preservation. This adds only an optional scene-focus effect.
   Dialog artwork is not part of the scene PP pass. Do not fake that with replacement masks or tint. */
disableSerialization;
params [["_display", displayNull, [displayNull]]];
if (isNull _display || {!hasInterface}) exitWith {};
private _medic = missionNamespace getVariable ["ACE_player", player];
private _nvg = !isNull _medic && {alive _medic} && {hmd _medic != ""} && {currentVisionMode _medic == 1};
if (_nvg && {cameraView == "GUNNER"}) then {
    if (currentWeapon _medic == binocular _medic && {binocular _medic != ""}) then {_nvg = false;};
    if (!isNull objectParent _medic && {!([_medic] call CBA_fnc_canUseWeapon)}) then {_nvg = false;};
};
if (!_nvg) exitWith {[_display] call ACME_fnc_minigameVisionClear;};
if !(_display getVariable ["ACME_NV_UnloadHook", false]) then {
    _display displayAddEventHandler ["Unload", {[_this select 0] call ACME_fnc_minigameVisionClear;}];
    _display setVariable ["ACME_NV_UnloadHook", true];
};
_display setVariable ["ACME_NV_Active", true];
[_display, true] call ACME_fnc_minigameVisionNative;
// No picture swapping, grayscale conversion, copied mask, native title recreation, or gain changes.
