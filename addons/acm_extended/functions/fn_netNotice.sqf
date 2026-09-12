// ACE's displayTextStructured is a LOCAL UI function, not a remote notice API.
params ["_text", ["_size", 2.5], ["_medic", objNull], ["_width", 10]];
if (isNull _medic) exitWith {};
if (local _medic) exitWith {
    if (hasInterface) then { [_text, _size, _medic, _width] call ace_common_fnc_displayTextStructured; };
};
["ACME_netNotice", _this, _medic] call CBA_fnc_targetEvent;
