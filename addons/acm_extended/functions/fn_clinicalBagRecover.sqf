/* Recover abandoned moves without inventing/deleting fluid, drug or fresh-blood identity. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
private _moves = _patient getVariable ["ACME_bagMoves", createHashMap];
{
    private _m = _moves get _x;
    _m params ["_origin", "_bag", "_medic", "_at", "_epoch"];
    if (isNull _medic || {!alive _medic} || {CBA_missionTime - _at > 120}) then {
        [_patient, _medic, _x, "cancel", _origin, _bag select 4, _bag select 3, _epoch] call ACME_fnc_clinicalBagMove;
        [_medic, "Disconnected bag returned to its original site; no fluid was discarded."] call ACME_fnc_clinicalNotice;
    };
} forEach (keys _moves);
