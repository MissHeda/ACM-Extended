/* Dispatch a discrete event to the patient owner. No physiology writes from a remote UI. */
params [["_patient", objNull, [objNull]], ["_reason", "miss", [""]]];
if (isNull _patient) exitWith {};
private _medic = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
private _serial = (missionNamespace getVariable ["ACME_laryngoEventSerial", 0]) + 1;
missionNamespace setVariable ["ACME_laryngoEventSerial", _serial];
[_patient, "laryngoConsequence", [_patient, _medic, [_patient] call ACME_fnc_clinicalEpoch,
    format ["%1:%2", clientOwner, _serial], _reason]] call ACME_fnc_ownerDispatch;
