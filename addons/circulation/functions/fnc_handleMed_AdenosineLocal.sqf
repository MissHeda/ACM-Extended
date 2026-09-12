/* B14: native handleMedicationEffects entry point retained.
   Unified medicationLocal records actual dose/rate before this callback.
   Adenosine no longer generates FatalVitals or uses ROSC to simulate a short AV block. */
params ["_patient"];
if (isNull _patient || {!alive _patient} || {!local _patient}) exitWith {};
[_patient] call ACME_fnc_ownerRegister;
