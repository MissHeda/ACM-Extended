// reserve the patient audio space for an important treatment sound.
// it deletes any currently playing junctional leak emitter and prevents a new leak clip until the action ends.
params ["_patient", ["_duration", 0]];
if (isNull _patient) exitWith {};
if !(_duration isEqualType 0) then { _duration = 0; };
if !(finite _duration) then { _duration = 0; };

private _until = time + (_duration max 0);
_patient setVariable ["ACME_SfxBusyUntil", _until, true];

private _src = _patient getVariable ["ACME_JuncLeakSfxSrc", objNull];
if (!isNull _src) then { deleteVehicle _src; };
_patient setVariable ["ACME_JuncLeakSfxSrc", objNull, true];
_patient setVariable ["ACME_JuncLeakNext", _until + 0.5 + random 2, true];
