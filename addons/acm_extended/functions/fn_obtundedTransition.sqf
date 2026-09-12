// Legacy compatibility entry point. B49 removed the forced-prone/forced-back obtundation transition machine.
// Any stale delayed call from an older hot-loaded build is intentionally absorbed here and may only clean up the
// temporary engine-ragdoll bit. It never writes a posture or animation.
params [["_patient", objNull]];
if (isNull _patient || {!local _patient}) exitWith {};
_patient setVariable ["ACME_obtunded_transitioning", false, true];
_patient setVariable ["ACME_obtunded_collapseInFlight", -1, false];
_patient setVariable ["ACME_obtunded_forcedBack", false, true];
_patient setVariable ["ACME_obtunded_treatmentHold", false, true];
