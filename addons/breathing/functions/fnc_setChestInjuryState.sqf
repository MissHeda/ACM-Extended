#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Authoritative breathing-owned setter for the native chest-injury presentation flag.
 *
 * Extended subsystems may cause a chest injury, but they no longer own the ACM state variable directly.
 * Keep the state mutation in the breathing addon so future state invariants/network policy have one endpoint.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Chest injury state <BOOL>
 *
 * Return Value:
 * Applied state <BOOL>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_state", true, [true]]
];

if (isNull _patient) exitWith {false};
_patient setVariable [QGVAR(ChestInjury_State), _state, true];
_state
