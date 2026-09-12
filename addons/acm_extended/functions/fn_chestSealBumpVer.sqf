/* Server-only commit of the collaborative chest state. Legacy six-column records
   remain globally available to ACE/ACM/Extended consumers. The UI additionally reads
   ONE atomic [epoch, revision, holes, wasted seals, NCD sides] envelope. */
params ["_patient", ["_rows", []]];
if (!isServer || {isNull _patient}) exitWith {};
private _epoch = _patient getVariable ["ACME_CS_netEpoch", ""];
if (_epoch == "") then {
    ACME_NA2_sequence = (missionNamespace getVariable ["ACME_NA2_sequence", 0]) + 1;
    _epoch = format ["%1:%2:%3", netId _patient, CBA_missionTime, ACME_NA2_sequence];
    _patient setVariable ["ACME_CS_netEpoch", _epoch, true];
};
private _ver = (_patient getVariable ["ACME_CS_holeVer", 0]) + 1;
// Only the enriched envelope carries IDs. Existing medical readers retain SIX columns.
if (count _rows == 0) then { _rows = _patient getVariable ["ACME_CS_holeData", []]; };
private _prior = (_patient getVariable ["ACME_CS_netSnapshot", []]) param [2, []];
private _used = [];
private _sequence = _patient getVariable ["ACME_CS_holeSequence", 0];
private _data = [];
{
    private _row = _x;
    private _id = _row param [8, ""];
    if (_id == "") then {
        private _geometry = [_row select [0, 6]] call ACME_fnc_chestSealKey;
        private _match = _prior findIf {
            !((_x param [8, ""]) in _used) && {([_x select [0, 6]] call ACME_fnc_chestSealKey) isEqualTo _geometry}
        };
        if (_match >= 0) then { _id = (_prior select _match) param [8, ""]; };
    };
    if (_id == "" || {_id in _used}) then {
        _sequence = _sequence + 1;
        _id = format ["%1/hole/%2", _epoch, _sequence];
    };
    _used pushBack _id;
    _data pushBack ((_row select [0, 6]) + [0, 0, _id]);
} forEach _rows;
_patient setVariable ["ACME_CS_holeSequence", _sequence, false];
private _wasted = (_patient getVariable ["ACME_CS_wastedData", []]) apply {+_x};
private _ncd = +(_patient getVariable ["ACME_CS_ncdPlacedSides", []]);
private _snapshot = [_epoch, _ver, _data, _wasted, _ncd];
_patient setVariable ["ACME_CS_holeVer", _ver, true];
_patient setVariable ["ACME_CS_netSnapshot", _snapshot, true];
private _entry = ACME_CS_sessions getOrDefault [netId _patient, [_patient, []]];
private _viewers = (_entry select 1) apply {_x select 0};
if !(_viewers isEqualTo []) then {
    ["ACME_CS_snapshot", [_patient, _snapshot], _viewers] call CBA_fnc_targetEvent;
};
_snapshot
