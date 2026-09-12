// stop the looping junctional packing sfx immediately. it is safe to call twice.
// it is called on a pack cancel or failure, and by junctionalPackDone when the packing completes.
params ["_medic"];
if (isNull _medic) exitWith {};
private _src = _medic getVariable ["ACME_JuncPackSfxSrc", objNull];
if (!isNull _src) then { deleteVehicle _src; };
_medic setVariable ["ACME_JuncPackSfxSrc", objNull];
