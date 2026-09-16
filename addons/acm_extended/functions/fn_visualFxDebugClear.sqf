params ["_medic","_patient"];
if (isNull _patient) exitWith {};
{_patient setVariable [format ["ACME_visualFxDebug_%1",_x],0,true];} forEach ["hypoxia","hypotension","hypercapnia","ketamine","syncope"];
if (!isNull _medic) then {["Visual FX debug overrides cleared.",1.5,_medic] call ace_common_fnc_displayTextStructured;};
