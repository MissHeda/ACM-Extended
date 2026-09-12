// offer the swap only when there is actually a machine to swap it in, and only when it is worth doing. a full
// battery does not need replacing, and offering it anyway just clutters an already busy menu.
params ["_patient"];
if (isNull _patient) exitWith { false };
if !(_patient getVariable ["ACME_vent_connected", false]) exitWith { false };
((_patient getVariable ["ACME_vent_battery", 100]) < 90)
