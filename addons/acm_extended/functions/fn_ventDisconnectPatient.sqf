/* Manual recovery uses the same serialized allocation as automatic death recovery. */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]]];
if (isNull _medic || {!local _medic} || {isNull _patient}) exitWith {};
if !([_medic, "ventilator", true] call ACME_fnc_procedureAllowed) exitWith {};
["ACME_ventCustodyRequest", ["return", _medic, _patient]] call CBA_fnc_serverEvent;
