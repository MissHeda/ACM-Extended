// Compatibility debug action. The historical name is retained so existing menus/keybinds do not break, but B49
// no longer has a locked-back obtunded posture. This toggles the same free state used by every other debug path.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!isPlayer _patient) exitWith {
    ["[ACME debug] obtundation is player-only.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
private _on = !(_patient getVariable ["ACME_obtunded", false]);
[_patient, _on, true, "free", "debug"] call ACME_fnc_obtundedSet;
[format ["[ACME debug] obtunded state: %1", ["OFF","ON"] select _on], 2, _medic] call ace_common_fnc_displayTextStructured;
