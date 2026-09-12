// induce or step hypothermia on a patient, the third lethal-triad axis.
// each press steps one stage colder and then wraps back to normothermic: 37, then 34 for mild, then 31 for moderate,
// then 28 for severe, then 37, cleared.
// cold drives coagulopathy, compounding with citrate hypocalcaemia, pressor refractoriness, compounding with
// acidosis, and bradycardia, all handled in fn_circhandle from the core temp set here.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};

private _temp = _patient getVariable ["ACME_hypo_temp", 37];
private _new = switch (true) do {
    case (_temp >= 35.5): {34};  // -> mild
    case (_temp >= 32.5): {31};  // -> moderate
    case (_temp >= 29.5): {28};  // -> severe
    default {37};  // -> cleared (normothermic)
};
[_patient, _new, true, false, false] call ACME_fnc_hypothermiaTemperatureCommit;
if (_new < 36) then {
    ACME_circ_activePatients pushBackUnique _patient;
};

private _label = switch (true) do {
    case (_new >= 36): {"cleared: normothermic (37.0 C)"};
    case (_new >= 33): {format ["MILD hypothermia (%1.0 C)", _new]};
    case (_new >= 30): {format ["MODERATE hypothermia (%1.0 C)", _new]};
    default {format ["SEVERE hypothermia (%1.0 C)", _new]};
};
[format ["Core temp: %1", _label], 2.5, _medic] call ace_common_fnc_displayTextStructured;
// the activity-log line is removed, because it revealed the condition of the patient.
