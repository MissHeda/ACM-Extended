/* Reserve one device before any patient state or provider inventory changes. */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]]];
if (isNull _medic || {!local _medic} || {isNull _patient}) exitWith {};
if !([_medic, "ventilator"] call ACME_fnc_procedureAllowed) exitWith {};
[{ace_medical_gui_pendingReopen = false;}, []] call CBA_fnc_execNextFrame;
["ACME_ventCustodyRequest", ["attach", _medic, _patient]] call CBA_fnc_serverEvent;
