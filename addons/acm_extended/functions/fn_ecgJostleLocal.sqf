/* Patient-owner lease for harmless monitor motion artifact. */
params ["_patient", ["_key", "", [""]], ["_active", true, [true]]];
if (isNull _patient || {_key == ""}) exitWith {};
if (!local _patient) exitWith {[_patient, "ecgJostle", _this] call ACME_fnc_ownerDispatch;};
private _now = CBA_missionTime;
private _leases = (_patient getVariable ["ACME_ecgJostleLeases", []]) select {(_x param [1,-1]) > _now && {(_x param [0,""]) != _key}};
if (_active) then {_leases pushBack [_key, _now + (missionNamespace getVariable ["ACME_ecgJostleLeaseSec", 180])];};
_patient setVariable ["ACME_ecgJostleLeases", _leases, true];
