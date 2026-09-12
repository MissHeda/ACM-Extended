#include "\x\ACM\addons\circulation\script_component.hpp"
/* Same exact-site fraction for fluid and syringe settlement. IO never borrows an IV's leak.
   A compromised distal catheter loses 80% in this bounded GAME model; native stage-2
   infiltration retains its native 20% loss. Fractions compose, never create mass. */
params ["_patient", "_part", "_site"];
if (_site < 0) exitWith {1};
_part = toLowerANSI _part;
if (_part == "ej") then {_part = "head";};
private _pi = ALL_BODY_PARTS find _part;
if (_pi < 0 || {!(_site in [0,1,2])}) exitWith {0};
private _fraction = 1;
if (GVAR(IVComplications)) then {
    private _comp = (GET_IV_COMPLICATIONS_FLOW_X(_patient,_pi,_site)) max 0 min 2;
    _fraction = [1,1,0.8] select _comp;
};
if (_patient getVariable [format ["ACME_ivCompromised_%1_%2",_part,_site],false]) then {
    _fraction = _fraction * 0.2;
};
_fraction max 0 min 1
