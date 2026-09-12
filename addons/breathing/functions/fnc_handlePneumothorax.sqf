/* ACM injury entry, replaced by ACM Extended B35.
   Only genuine new chest injury calls this entry. Treatment, restore and worker
   enrollment use ptxEnsure. The shared owner worker alone progresses pleural air. */
params ["_patient"];
if (isNull _patient) exitWith {};
[_patient, 1] call ACME_fnc_ptxInjury;
