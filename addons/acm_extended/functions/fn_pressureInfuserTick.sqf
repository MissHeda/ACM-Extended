/* NA5 cuff decay. Flow reads the selected bag's cuff in fn_getIVFlowRate.sqf.
   Drop absent and empty bags without rewriting unchanged maps each tick.
   A deflated cuff remains fitted and can be pumped without spending another item. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
private _cuffs = _patient getVariable ["ACME_piCuffs", createHashMap];
if (count _cuffs == 0) exitWith {};
private _live = [];
{
    {_x params ["_type", "_remaining"]; if (_remaining > 0.5) then {_live pushBack (_x param [8, ""]);};} forEach _y;
} forEach (_patient getVariable ["ACM_circulation_IV_Bags", createHashMap]);
private _drop = [];
{
    if (!(_x in _live)) then {_drop pushBack _x;};
} forEach _cuffs;
if !(_drop isEqualTo []) then {
    {_cuffs deleteAt _x;} forEach _drop;
    [_patient, "cuffs", _cuffs] call ACME_fnc_pressureInfuserStateCommit;
};
