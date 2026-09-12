/* Reserve actual solution and one syringe before a bag transaction.
   Partial-vial volume is background tracked and can fund later syringes/infusions. */
params ["_medic", "_med", "_ml", "_size"];
if (!local _medic || {_ml <= 0} || {!finite _ml} || {!(_size in [1,3,5,10])} || {_ml > _size + 0.001}) exitWith {[]};
private _syringe = format ["ACM_Syringe_%1", _size];
if (([_medic, _syringe] call ace_common_fnc_getCountOfItem) < 1) exitWith {[]};
if !([_medic, _med, _ml] call ACME_fnc_vialTake) exitWith {[]};
private _refundItems = [];
if !(missionNamespace getVariable ["ACM_circulation_reusableSyringe", false]) then {
    _medic removeItem _syringe;
    _refundItems pushBack _syringe;
};
[_medic, _refundItems, [_med, _ml]]
