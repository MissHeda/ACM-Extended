// stop the accuvac and suction-bag sfx. it is called from the success and failure callbacks of the suction action,
// so the sound stops the moment the timer finishes or the treatment is interrupted.
params ["_medic"];
private _src = _medic getVariable ["ACME_suction_sfxSource", objNull];
if (!isNull _src) then { deleteVehicle _src; };
_medic setVariable ["ACME_suction_sfxSource", objNull];
