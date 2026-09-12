/* One observed pressure ratio changes trapped gas. Fixed altitude is inert.
Expansion/contraction never creates another pulmonary leak. */
params [["_patient",objNull,[objNull]],["_factor",1,[0]]];
if (isNull _patient || {!local _patient} || {!alive _patient} || {!finite _factor} || {_factor<=0}) exitWith {};
_factor=_factor max 0.2 min 5;
if (abs (_factor-1)<0.0000001) exitWith {};
if (count (_patient getVariable ["ACME_ptx_state",[]])==0
    && {(_patient getVariable ["ACM_breathing_Pneumothorax_State",0])<=0}
    && {!(_patient getVariable ["ACM_breathing_TensionPneumothorax_State",false])}) exitWith {};
private _s=[_patient] call ACME_fnc_ptxEnsure;
private _air=_s select 1;
if (_air<=0) exitWith {};
private _c=[_patient] call ACME_fnc_ptxContext;
private _in=(_s select 2)*(_c select 4)+((0.35*(_c select 0)) min 1.4);
// A sufficient communicating outlet equalizes with the surroundings.
if ((_c select 2)>_in+0.05) exitWith {};
private _new=(_air*_factor) max 0 min 32;
_s set [1,_new];
_s set [8,((_s select 8)*_factor) min _new];
private _tension=_patient getVariable ["ACM_breathing_TensionPneumothorax_State",false];
if (_factor>1) then {
    _s set [3,0];
    _s set [4,((_s select 4)+((_new-_air) max 0)*0.5) min 1];
    if (_air*_factor>4) then {_s set [4,1];_tension=true;};
} else {
    _s set [4,((_s select 4)-(_air-_new)*0.5) max 0];
    if ((_s select 4)<=0.1 && {_new<3}) then {_tension=false;};
};
[_patient,_s,_tension] call ACME_fnc_ptxPublish;
