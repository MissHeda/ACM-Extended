// an ACE treatment-action callback, where the framework passes [_medic, _patient, _bodyPart].
// it toggles the silent automatic AED NIBP cuff cycle on the patient.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith { ["ACME_ownerCommand", [_patient, "autoBP", _this], _patient] call CBA_fnc_targetEvent; };

private _active = _patient getVariable ["ACME_autoBP_Active", false];
_active = !_active;
_patient setVariable ["ACME_autoBP_Active", _active, true];
_patient setVariable ["ACME_autoBP_Medic", _medic, true];

if (_active) then {
    _patient setVariable ["ACME_autoBP_NextTime", CBA_missionTime, true];
    ACME_autoBP_patients pushBackUnique _patient;
    missionNamespace setVariable ["ACME_debug_target", _patient];
    missionNamespace setVariable ["ACME_debug_lastTreatmentTarget", _patient];
    missionNamespace setVariable ["ACME_tbi_debugTarget", _patient];
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_patient, "activity", "Auto BP cycle started (q2min)", []] call ace_medical_treatment_fnc_addToLog;
    };
} else {
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_patient, "activity", "Auto BP cycle stopped", []] call ace_medical_treatment_fnc_addToLog;
    };
};
