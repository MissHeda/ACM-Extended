/* Megacode patients use C_man_1, which native CIV_F filtering excludes.
   Ordinary patients retain ACM's faction policy and native dogtag data. */
params ["_medic", "_patient"];
if (isNull _patient) exitWith {false};
if (_patient getVariable ["ACME_isMegacode", false]) exitWith {true};
_this call ACM_core_fnc_canCheckDogtag
