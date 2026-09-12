params ["_unit", ["_epoch", -1]];
if (_epoch < 0) then {_epoch = [_unit] call ACME_fnc_clinicalEpoch;};
if (isNull _unit || {!alive _unit} || {!local _unit} || {_epoch != ([_unit] call ACME_fnc_clinicalEpoch)}) exitWith {};
if ((["leftarm", "rightarm", "leftleg", "rightleg"] findIf {(_unit getVariable [format ["ACME_Junc_%1", _x], ""]) in ["open", "packed", "xstat"]}) >= 0) then {
    [_unit] call ACME_fnc_junctionalStartBleed;
};
