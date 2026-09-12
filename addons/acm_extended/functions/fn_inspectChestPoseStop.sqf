// Success and cancellation both end the pose when the treatment actually ends.
params [["_medic", objNull, [objNull]], ["_abort", false, [false]]];
[_medic, "inspect"] call ACME_fnc_treatmentPoseStop;
