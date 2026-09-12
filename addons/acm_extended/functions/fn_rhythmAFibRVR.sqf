// a debug action: toggle AFib with RVR, code 100, on the patient.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 100, "AFib with RVR", (missionNamespace getVariable ["ACME_rhythm_afibHR", 165])] call ACME_fnc_rhythmToggle;
