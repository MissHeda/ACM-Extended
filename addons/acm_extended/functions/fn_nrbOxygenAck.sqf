params ["_patient", "_session", "_sequence", "_ok"];
if (isNull _patient || {!local _patient}) exitWith {};
if ((_patient getVariable ["ACME_nrb_session", ""]) != _session) exitWith {};
private _pending = _patient getVariable ["ACME_nrb_drawPending", []];
if (count _pending < 3 || {(_pending select 0) != _session} || {(_pending select 1) != _sequence}) exitWith {};
private _liters = (missionNamespace getVariable ["ACME_nrb_tankCapacityL", 425]) / ((missionNamespace getVariable ["ACME_nrb_tankUnits", 283]) max 1);
[_patient, "ACME_nrb_o2Pending", ((_patient getVariable ["ACME_nrb_o2Pending", 0]) - _liters) max 0] call ACME_fnc_setVarNet;
_patient setVariable ["ACME_nrb_drawPending", [], true];
if (!_ok) then {
    [_patient, -1, false, -1, true, true] call ACME_fnc_nrbStateCommit;
    ["ACME_nrbSound", [_patient, false]] call CBA_fnc_serverEvent;
    _patient setVariable ["ACME_nrb_sfxWanted", false, false];
    ["Oxygen tank depleted. NRB flow stopped.", 3, _patient getVariable ["ACME_nrb_medic", objNull]] call ACME_fnc_netNotice;
};
