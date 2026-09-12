// a fresh pack in. it resets the warned-flags too, so LOW and CRITICAL will chirp again on the new one rather than
// staying silent because they already fired on the old.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
_patient setVariable ["ACME_vent_battery", 100, true];
_patient setVariable ["ACME_vent_battWarned", 0, true];
playSound "ACME_VentClick";
["Fresh battery fitted. Ventilator at 100%.", 2, _medic] call ace_common_fnc_displayTextStructured;
