/* B57: retire the medical-menu crouch request.
   No special menu animation exists anymore, so there is no work pose to blend out of. AUTO is restored only to
   release the player's stance controls; no stand-up animation is requested. */
params [["_medic", objNull, [objNull]], ["_silent", false, [false]], ["_epoch", -1, [0]]];
if (isNull _medic) exitWith {};
private _state = _medic getVariable ["ACME_menuPose", []];
if (_state isEqualTo []) exitWith {};
private _currentEpoch = _state param [0, -1];
if (_epoch >= 0 && {_currentEpoch != _epoch}) exitWith {};
_medic setVariable ["ACME_menuPose", []];
if (!local _medic || {_silent}) exitWith {};
_medic setUnitPos "AUTO";
