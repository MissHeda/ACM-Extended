// ACE leaves this action's animation fields empty; one controller owns entry, work and exit.
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]]];
[_medic, "inspect", 6, _patient] call ACME_fnc_treatmentPoseStart;
