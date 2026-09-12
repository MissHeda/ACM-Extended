// Compatibility entry point. Mode/rhythm/charge are revalidated by the same authority as every other shock.
params ["_medic", "_patient", ["_label", "Synchronized cardioversion"]];
[_medic, _patient] call ACME_fnc_shockRequest;
