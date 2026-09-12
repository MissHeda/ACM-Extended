// One global, deletable wrapping loop per provider, including self-treatment.
// The token prevents a delayed server stop from deleting a newer episode.
params ["_medic", "_patient", ["_bodyPart", ""], ["_classname", "ACME_WrapJunctional"]];
if (isNull _medic || {!local _medic} || {!alive _medic} || {isNull _patient}) exitWith {};
[_medic] call ACME_fnc_wrapSfxStop;
private _serial = (missionNamespace getVariable ["ACME_wrapSfxSerial", 0]) + 1;
missionNamespace setVariable ["ACME_wrapSfxSerial", _serial];
private _token = format ["%1:%2", clientOwner, _serial];
_medic setVariable ["ACME_wrapSfxState", [_token, _patient, toLower _bodyPart, toLower _classname]];
["ACME_wrapSfx", ["start", _medic, _patient, _token, clientOwner]] call CBA_fnc_serverEvent;
