/* Real tissue trauma, not ordinary missed aim. Owner serializes patient state. */
params ["_patient", ["_cause", "trauma"]];
[_patient, "trauma"] call ACME_fnc_laryngoConsequence;
