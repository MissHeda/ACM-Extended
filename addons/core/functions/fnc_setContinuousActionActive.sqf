#include "..\script_component.hpp"
/* Author: ACM Extended Fork. Core-owned writer for the local continuous-action lock. */
params [["_active", false, [true]]];
missionNamespace setVariable [QGVAR(ContinuousAction_Active), _active];
_active
