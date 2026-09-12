// Debug/ACE action: toggle the real obtunded state on a player.
// B49: debug uses the same free-posture state and the same blur/vignette/audio stack as physiological obtundation.
params ["_medic", "_patient", "_bodyPart", ["_legacyPosture", "free"]];
if (isNull _patient) exitWith {};
if (!isPlayer _patient) exitWith {
    ["Obtundation only applies to players, not AI.", 2.5, _medic] call ace_common_fnc_displayTextStructured;
};
private _on = !(_patient getVariable ["ACME_obtunded", false]);
[_patient, _on, true, "free", "debug"] call ACME_fnc_obtundedSet;
[(["Obtunded cleared.", "Obtunded induced: free posture, full visual impairment."] select _on), 2.5, _medic] call ace_common_fnc_displayTextStructured;
