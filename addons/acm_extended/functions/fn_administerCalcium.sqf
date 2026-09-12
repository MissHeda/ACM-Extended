// administer one push of calcium chloride, 1 g in 10 ml. it adds to the cumulative calcium credit of the patient,
// which circhandle nets against the citrate deficit to raise the ionized calcium, restoring contractility and
// clotting. the consumed item is handled by the items[] of the treatment action, and this simply books the dose.
// it is called from the ACME_GiveCalcium treatment action, where _this is [medic, patient, bodypart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};

private _perDose = missionNamespace getVariable ["ACME_ca_gramsPerDose", 1];
private _given = [_patient, _perDose, "add", true, false] call ACME_fnc_calciumCreditCommit;

// make sure the patient is being ticked, so the new credit takes effect promptly.
if (!isNil "ACME_circ_activePatients") then {
    ACME_circ_activePatients pushBackUnique _patient;
};

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "medication", format ["Calcium chloride %1 g IV", _perDose], []] call ace_medical_treatment_fnc_addToLog;
};
[format ["Calcium chloride given (%1 g cumulative)", _given], 1.5, _medic, 13] call ace_common_fnc_displayTextStructured;
