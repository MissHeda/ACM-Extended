// Request removal from any provider; the patient owner owns state and sound teardown.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
["ACME_ownerCommand", [_patient, "nrbState", [_patient, _medic, false]], _patient] call CBA_fnc_targetEvent;
