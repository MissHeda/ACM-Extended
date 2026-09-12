// administer magnesium sulfate as a real ACM-style medication record. it does not terminate torsades instantly.
// fn_circhandle watches the Magnesium_IV effect curve and only terminates and suppresses torsades after the drug
// has reached a therapeutic effect. because this is a normal ACM medication adjustment, the effect persists and
// washes out after the push or bag is stopped instead of switching off immediately.
// _this, the ACE callback, is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", ["_bodyPart", "body"]];
if (isNull _patient) exitWith {};

["ace_medical_treatment_medicationLocal", [_patient, _bodyPart, "Magnesium_IV", 2000, true], _patient] call CBA_fnc_targetEvent;

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "medication", "Magnesium sulfate 2 g IV", []] call ace_medical_treatment_fnc_addToLog;
};
["Magnesium sulfate 2 g given.", 2, _medic, 13] call ace_common_fnc_displayTextStructured;
