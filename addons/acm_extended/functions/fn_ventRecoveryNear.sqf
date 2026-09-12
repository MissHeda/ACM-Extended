/* Shared vehicle bypasses distance. On foot, two null vehicle pointers do not match. */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_lastPos", [], [[]]], ["_lastVehicle", objNull, [objNull]]];
if (isNull _medic || {!alive _medic}) exitWith {false};
private _vehicle = if (isNull _patient) then {_lastVehicle} else {objectParent _patient};
if (!isNull _vehicle && {(objectParent _medic) isEqualTo _vehicle}) exitWith {true};
if (!isNull _patient) exitWith {(_medic distance _patient) <= 5};
if (count _lastPos != 3) exitWith {false};
((getPosASL _medic) distance _lastPos) <= 5
