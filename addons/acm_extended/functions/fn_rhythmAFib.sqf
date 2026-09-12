// a debug action: toggle atrial fibrillation at a controlled ventricular response, code 103.
// it is the same morphology as AFib-RVR, meaning no p wave, irregularly irregular and a fibrillatory baseline, and
// at a controlled rate of about 80 bpm instead of the rapid response.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 103, "Atrial Fibrillation", (missionNamespace getVariable ["ACME_rhythm_afibControlledHR", 80])] call ACME_fnc_rhythmToggle;
