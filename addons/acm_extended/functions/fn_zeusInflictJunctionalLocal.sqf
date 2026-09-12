// this runs where the target unit is local. it places a junctional bleed on a random uninjured limb.
// call or remoteexec it as [_unit] call ACME_fnc_zeusInflictJunctionalLocal.
params ["_unit"];
if (isNull _unit || {!alive _unit} || {!local _unit}) exitWith {};
private _parts = ["leftarm", "rightarm", "leftleg", "rightleg"];
private _free = _parts select { (_unit getVariable [format ["ACME_Junc_%1", _x], ""]) == "" };
if (_free isEqualTo []) exitWith {
    ["Junctional module: all four limbs already have a junctional bleed.", 2] call ace_common_fnc_displayTextStructured;
};
[_unit, selectRandom _free] call ACME_fnc_junctionalInflict;
