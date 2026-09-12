// a debug action: toggle polymorphic vt, or torsades, code 102, on the patient.
// it is induced as torsades with a pulse, meaning perfusing, so the polymorphic morphology renders. pulseless
// torsades would route through the monomorphic-vt display branch of ACM.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 102, "Torsades (polymorphic VT)", (missionNamespace getVariable ["ACME_rhythm_torsadesHR", 210])] call ACME_fnc_rhythmToggle;
