// partially expose the chest from a fully-wrapped HPMK, taking the state from wrapped to exposed.
// the patient stays mostly wrapped, so passive rewarming continues because ACME_hpmk_on stays true, and the chest
// and left arm open up for care while the right arm and both legs remain sealed. the wrapped body overlay swaps to
// the exposed image and the canTreatCached gate widens to allow head, body, meaning chest, and left-arm
// treatments.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if ((_patient getVariable ["ACME_hpmk_state", ""]) != "wrapped") exitWith {};

[_patient, "exposed", true, false] call ACME_fnc_hpmkStateCommit;
// hpmk_on is left true on purpose. they are still mostly wrapped, so passive rewarming keeps running.

["Chest + left arm exposed", 3, _medic] call ace_common_fnc_displayTextStructured;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "HPMK chest partially exposed", []] call ace_medical_treatment_fnc_addToLog;
};
