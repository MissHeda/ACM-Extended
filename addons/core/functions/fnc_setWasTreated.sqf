#include "..\script_component.hpp"
/* Author: ACM Extended Fork. Core-owned writer for ACM's treatment-history flag. */
params [["_patient", objNull, [objNull]], ["_treated", true, [true]], ["_public", true, [true]]];
if (isNull _patient) exitWith {false};
_patient setVariable [QGVAR(WasTreated), _treated, _public];
true
