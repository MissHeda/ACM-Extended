// a debug action: toggle atrial tachycardia, code 101, on the patient.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 101, "Atrial Tachycardia", (missionNamespace getVariable ["ACME_rhythm_atHR", 185])] call ACME_fnc_rhythmToggle;
