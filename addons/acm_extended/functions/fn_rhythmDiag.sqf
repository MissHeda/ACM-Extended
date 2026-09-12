// retired debug chain logger for release builds. keep the callback present so any stale references fail quietly.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
true
