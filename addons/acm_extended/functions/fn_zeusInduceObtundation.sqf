// Zeus module: toggle awake obtundation. The perceptual/motor state is intentionally player-only; B49 removed the
// former AI-only forced ragdoll/back-pose surrogate because obtundation no longer owns body posture at all.
params ["_logic"];
if (isNull _logic) exitWith {};
private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then {_unit = attachedTo _logic;};
private _cleanup = {if (!isNull _logic) then {deleteVehicle _logic;};};
if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Obtundation module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!alive _unit) exitWith {
    ["Obtundation module: target must be alive.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!isPlayer _unit) exitWith {
    ["Obtundation module: the awake obtunded state is player-only.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
private _want = !(_unit getVariable ["ACME_obtunded", false]);
[_unit, _want, true, "free", "zeus"] call ACME_fnc_obtundedSet;
[format ["Obtundation %1 %2.", ["cleared on","induced on"] select _want, name _unit], 2] call ace_common_fnc_displayTextStructured;
call _cleanup;
