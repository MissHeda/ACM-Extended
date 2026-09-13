// Release a casualty animation lease if and only if the caller still owns the same token.
params [["_patient", objNull, [objNull]], ["_token", "", [""]]];
if (isNull _patient || {_token == ""}) exitWith {};
if (!local _patient) exitWith {[_patient, "patientAnimRelease", [_patient, _token]] call ACME_fnc_ownerDispatch;};
private _lock = _patient getVariable ["ACME_patientAnimLock", []];
if ((_lock param [0, ""]) == _token) then {_patient setVariable ["ACME_patientAnimLock", [], true];};
