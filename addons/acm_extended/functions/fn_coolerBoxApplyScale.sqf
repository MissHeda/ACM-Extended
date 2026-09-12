// Named, object-scoped replacement for remoteExec ["call", ...].
// Replay remains attached to the cooler object's JIP lifetime.
params [["_box", objNull, [objNull]], ["_scale", 0.65, [0]]];
if (isNull _box || {_scale <= 0}) exitWith {};
if !((typeOf _box) in ["ACME_BloodCoolerBox_CSWB1U", "ACME_BloodCoolerBox_CSWB2U", "ACME_BloodCoolerBox_CSWB4U"]) exitWith {};
_box enableSimulation false;
_box setObjectScale _scale;
