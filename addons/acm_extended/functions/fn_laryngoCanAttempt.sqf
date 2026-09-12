/* Difficulty changes the required technique, never eligibility. All grades remain attemptable. */
params ["_patient"];
if (isNull _patient) exitWith {[false, "No patient."]};
[true, ""]
