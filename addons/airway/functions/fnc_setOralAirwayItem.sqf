#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Airway-owned writer for the native oral-airway slot.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Oral airway type <STRING>
 * 2: Public <BOOL> (default true)
 *
 * Return Value:
 * Success <BOOL>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_type", "", [""]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {false};
_patient setVariable [QGVAR(AirwayItem_Oral), _type, _public];
true
