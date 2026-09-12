/* Called when the blade enters. Transport an event; never write physiology from a remote UI. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {};
private _serial = (missionNamespace getVariable ["ACME_laryngoStimSerial", 0]) + 1;
missionNamespace setVariable ["ACME_laryngoStimSerial", _serial];
[_patient, "laryngoStimulus", [_patient, ACE_player, [_patient] call ACME_fnc_clinicalEpoch, format ["%1:%2", clientOwner, _serial]]] call ACME_fnc_ownerDispatch;
