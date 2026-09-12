/* B13: native effective units are now mg/kg and incorporate dose-specific binding. */
params ["_patient"];
if (isNull _patient) exitWith {0};
([_patient, "Rocuronium_IV", false] call ace_medical_status_fnc_getMedicationCount)
    + ([_patient, "Rocuronium", false] call ace_medical_status_fnc_getMedicationCount)
