/* Compatibility entry point: a requested wet gag must meet the shared consecutive-miss gate. */
params [["_kind", "dry"]];
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (isNull _patient) exitWith {};
[_patient, "gag"] call ACME_fnc_laryngoFail;
