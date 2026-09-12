// a debug action: toggle SVT, supraventricular tachycardia, code 104, on the patient.
// it is narrow-complex, very fast and regular, with no visible p wave, because the p is buried in the preceding t. it
// is a classic synchronized-cardioversion target when unstable, and it is treated as cardiovertible alongside
// AFib-RVR, see acme_rhythm_cardiovertible.
// it carries the same symptomatic pain, obtundation and hemodynamic-instability profile as the other atrial rhythms,
// handled in fn_rhythmtick.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 104, "SVT", (missionNamespace getVariable ["ACME_rhythm_svtHR", 190])] call ACME_fnc_rhythmToggle;
