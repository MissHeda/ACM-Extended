/* Stable per-object episode generation. Only the patient owner increments this on reset. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {-1};
_patient getVariable ["ACME_clinicalEpoch", 0]
