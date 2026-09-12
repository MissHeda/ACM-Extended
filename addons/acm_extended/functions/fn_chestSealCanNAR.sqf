params ["_patient"];
if (isNull _patient) exitWith {false};
if !(missionNamespace getVariable ["ACM_breathing_pneumothoraxEnabled", true]) exitWith {false};
[_patient] call ACME_fnc_chestSealCanApply
