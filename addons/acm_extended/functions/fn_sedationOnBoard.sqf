params ["_patient"];
if (isNull _patient) exitWith {0};
([_patient] call ACME_fnc_sedationComponents) select 5
