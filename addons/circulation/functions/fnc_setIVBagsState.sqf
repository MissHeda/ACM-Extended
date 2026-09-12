#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Circulation-owned mutation endpoint for ACM's IV-bag state map.
 *
 * Extended infusion/Y-line/transfusion systems delegate their final native-state publication here. This keeps
 * the ACM variable under its owning addon while retaining the public ACM state shape for compatibility.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: IV bag map <HASHMAP>
 * 2: Public <BOOL> (default true)
 *
 * Return Value:
 * Success <BOOL>
 *
 * Public: Yes
 */
params [
    ["_patient", objNull, [objNull]],
    ["_bags", createHashMap, [createHashMap]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {false};
_patient setVariable [QGVAR(IV_Bags), _bags, _public];
true
