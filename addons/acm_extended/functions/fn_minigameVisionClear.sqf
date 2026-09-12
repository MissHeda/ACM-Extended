/* Release this procedure's interest in the shared, addon-owned focus effect. */
params [["_display", displayNull, [displayNull]]];
if (!isNull _display) then {_display setVariable ["ACME_NV_Active", false];};
[_display, false] call ACME_fnc_minigameVisionNative;
