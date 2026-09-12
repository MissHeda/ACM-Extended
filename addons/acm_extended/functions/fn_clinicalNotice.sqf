params ["_medic", "_text", ["_duration", 3]];
if (isNull _medic) exitWith {};
if (!local _medic) exitWith {["ACME_clinicalNotice", _this, _medic] call CBA_fnc_targetEvent;};
if (hasInterface && {_medic == player}) then {[_text, _duration] call ace_common_fnc_displayTextStructured;};
