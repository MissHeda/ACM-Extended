/* Monotonic CBA mission-time elapsed integration; no backlog after migration; cap = explicit stall policy. */
params ["_patient", "_channel", ["_nominal", 0.5], ["_cap", 5]];
private _key = "ACME_clock_" + _channel;
private _now = CBA_missionTime;
private _ownerKey = _key + "_owner";
private _sameOwner = (_patient getVariable [_ownerKey, -1]) == clientOwner;
private _last = if (_sameOwner) then {_patient getVariable [_key, _now]} else {_now};
_patient setVariable [_key, _now, false];
_patient setVariable [_ownerKey, clientOwner, false];
((_now - _last) max 0) min (_cap max 0)
