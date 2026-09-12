/* Wait for display teardown and the accepted bag, without swallowing a fast acknowledgement. */
params ["_patient", "_doseId", "_medic", "_part", "_token"];
missionNamespace setVariable ["ACME_infusion_clampToken", _token];
private _epoch = [_patient] call ACME_fnc_clinicalEpoch;
[{
    params ["_p", "_dose", "_m", "", "_token", "_epoch"];
    isNull _p || {!alive _m} || {_m != ACE_player} || {_epoch != ([_p] call ACME_fnc_clinicalEpoch)} ||
    {_token != (missionNamespace getVariable ["ACME_infusion_clampToken", ""])} ||
    {!dialog && {((_p getVariable ["ACME_infusion_BagMedications", []]) findIf {(_x select 0) == _dose}) >= 0}}
}, {
    params ["_p", "_dose", "_m", "_part", "_token", "_epoch"];
    if (isNull _p || {!alive _m} || {_m != ACE_player} || {_epoch != ([_p] call ACME_fnc_clinicalEpoch)} || {_token != (missionNamespace getVariable ["ACME_infusion_clampToken", ""])}) exitWith {};
    private _entries = _p getVariable ["ACME_infusion_BagMedications", []];
    private _i = _entries findIf {(_x select 0) == _dose};
    if (_i < 0 || {dialog}) exitWith {};
    private _bagId = (_entries select _i) param [23, ""];
    private _indices = [];
    {if ((_x param [23, ""]) == _bagId) then {_indices pushBack _forEachIndex;};} forEach _entries;
    uiNamespace setVariable ["ACME_RollerClamp_Context", [_p, _indices, _indices apply {(_entries select _x) select 0}, _epoch]];
    uiNamespace setVariable ["ACME_RollerClamp_Return", [_m, _p, _part]];
    createDialog "ACME_RollerClamp_Dialog";
}, [_patient, _doseId, _medic, _part, _token, _epoch], 60, {}] call CBA_fnc_waitUntilAndExecute;
