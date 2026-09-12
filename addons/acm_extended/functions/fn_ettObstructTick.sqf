// the cuff at the cords, for as long as it lasts.
// call it as [_patient] call ACME_fnc_ettObstructTick, from fn_circhandle.
// while a displaced cuff is sitting in the glottis the airway keeps producing. suction clears what is there and buys
// a window, and then it comes back, because the thing causing it has not been fixed. pushing the tube back in or
// pulling it out is what fixes it.
// the window is the point. without it this would be an unwinnable loop, which is the tedium worth avoiding, and with
// it, suctioning is worth doing and the medic gets a usable gap to work in.
params ["_patient"];
if (isNull _patient) exitWith {};
if (!(_patient getVariable ["ACME_ETT_Obstructing", false])) exitWith {};

private _now = CBA_missionTime;
if (_now > (_patient getVariable ["ACME_ETT_ObstructUntil", 0])) exitWith {
    [_patient, "ACME_ETT_Obstructing", false] call ACME_fnc_setVarNet;
    [_patient, "ACME_laryngo_fluidPersist", false] call ACME_fnc_setVarNet;
};

// cleared? start the quiet window. once it runs out, it produces again.
private _vom = _patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0];
private _bld = _patient getVariable ["ACM_airway_AirwayObstructionBlood_State", 0];
if ((_vom + _bld) > 0) exitWith { _patient setVariable ["ACME_ETT_ObstructNext", -1, true]; };

private _next = _patient getVariable ["ACME_ETT_ObstructNext", -1];
if (_next < 0) exitWith {
    _patient setVariable ["ACME_ETT_ObstructNext",
        _now + (missionNamespace getVariable ["ACME_ettObstructWindowSec", 12]), true];
};
if (_now < _next) exitWith {};

private _kind = if (_patient getVariable ["ACME_laryngo_bloody", false]) then {"Blood"} else {"Vomit"};
private _v = format ["ACM_airway_AirwayObstruction%1_State", _kind];
[_patient, _v, ((_patient getVariable [_v, 0]) max 2)] call ACME_fnc_setVarNet;
[_patient, "ACME_ETT_ObstructNext", -1] call ACME_fnc_setVarNet;
