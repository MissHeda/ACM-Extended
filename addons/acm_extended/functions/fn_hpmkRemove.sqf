// stow or remove the HPMK from either state, prepped or wrapped, taking the state to empty. it stops rewarming and
// hands the reusable kit back to whoever removes it.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
private _state = _patient getVariable ["ACME_hpmk_state", ""];
if (_state == "") exitWith {};

[_patient, "", true, false] call ACME_fnc_hpmkStateCommit;
if (!isNil "ACME_hpmk_activePatients") then { ACME_hpmk_activePatients = ACME_hpmk_activePatients - [_patient]; };
_medic addItem "ACM_HPMK";  // reusable. recovered, never destroyed

[([" HPMK stowed.", "HPMK removed."] select (_state == "wrapped")), 2.5, _medic] call ace_common_fnc_displayTextStructured;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "NAR HPMK removed (recovered)", []] call ace_medical_treatment_fnc_addToLog;
};
