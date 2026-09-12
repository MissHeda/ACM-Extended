/* Called once by patient owner's circulation tick. Integral of rate is admitted mg.
   Remaining durations are relative and survive save/load without wall-clock backfill. */
params ["_patient","_dt"];
private _rates = createHashMap;
if (_dt <= 0) exitWith {_rates};
private _queue = _patient getVariable ["ACME_medicationDriveQueue",[]];
private _keep = [];
{
    _x params ["_base","_mass","_remaining"];
    private _step = _dt min (_remaining max 0.000001);
    private _delivered = _mass * (_step / (_remaining max 0.000001));
    _rates set [_base,(_rates getOrDefault [_base,0]) + _delivered * 60 / _dt];
    if (_remaining > _dt + 0.000001) then {_keep pushBack [_base,(_mass - _delivered) max 0,_remaining - _dt];};
} forEach _queue;
_patient setVariable ["ACME_medicationDriveQueue",_keep,true];
[_patient,"ACME_ketRapidLoad",(_patient getVariable ["ACME_ketRapidLoad",0]) * (0.5 ^ (_dt / 20))] call ACME_fnc_setVarNet;
_rates
