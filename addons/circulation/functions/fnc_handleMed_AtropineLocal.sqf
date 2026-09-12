/* B13:Atropine: the native vitals loop owns onset and locality, not a disposable PFH. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
[_patient] call ACME_fnc_ownerRegister;
