// NA3. Never mutate a remote casualty from the operator's UI.
params ["_patient"];
if (isNull _patient) exitWith {};
[_patient getVariable ["ACM_circulation_AED_Provider", objNull], _patient] call ACME_fnc_shockRequest;
