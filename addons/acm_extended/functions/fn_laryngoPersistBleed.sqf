/* Compatibility entry point. Bounded real blood state, never a client-only perpetual refill. */
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (!isNull _patient) then {[_patient, "trauma"] call ACME_fnc_laryngoConsequence;};
