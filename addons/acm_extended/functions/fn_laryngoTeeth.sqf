/* An actual fracture retains its sound and persistent artwork; pre-break creaks are removed. */
params ["_patient"];
[_patient, "teeth"] call ACME_fnc_laryngoConsequence;
