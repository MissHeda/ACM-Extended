// re-cover a partially-exposed HPMK chest, taking the state from exposed to wrapped. it swaps the exposed image
// back to the fully-wrapped overlay and tightens the canTreatCached gate back to head-only.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if ((_patient getVariable ["ACME_hpmk_state", ""]) != "exposed") exitWith {};

[_patient, "wrapped", true, false] call ACME_fnc_hpmkStateCommit;

["Chest re-covered", 3, _medic] call ace_common_fnc_displayTextStructured;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "HPMK chest re-covered", []] call ace_medical_treatment_fnc_addToLog;
};
