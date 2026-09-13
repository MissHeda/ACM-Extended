// stage 2 of the HPMK: wrap the prepped kit, taking the state from prepped to wrapped. this is where passive
// rewarming begins, because ACME_hpmk_on going true drives fn_hpmktick and the ground-blanket spawner. the kit
// was already taken out at prep, so nothing is removed here.
// passive external rewarming retains the body heat of the patient to let a stable patient drift their core temp
// back up, and it does little for an unstable or non-perfusing patient, which is clinically correct, because that
// needs active rewarming.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (!local _patient) exitWith { ["ACME_ownerCommand", [_patient, "hpmkWrap", _this], _patient] call CBA_fnc_targetEvent; };
if (isNull _patient) exitWith {};

private _lyingState = _patient getVariable ["ACM_core_Lying_State", false];
private _isLying = if (_lyingState isEqualType true) then {_lyingState} else {_lyingState > 0};
private _eligible = (_patient getVariable ["ACE_isUnconscious", false]) || {_isLying};
if (!_eligible) exitWith {
    private _receiver = _patient getVariable ["ACME_hpmk_provider", _medic];
    [_receiver, _patient, true] call ACME_fnc_hpmkRemove;
};

// our pose first. if the head of this casualty is being held up, put it down properly with the release animation
// and tear the elevation down before rolling them. rolling on top of an elevated head is two systems fighting
// over one body, and ours loses silently and leaves the pose stuck.
private _pYield = if (!isNil "_patient") then { _patient } else { objNull };
if (!isNull _pYield) then { [_pYield] call ACME_fnc_headElevYieldForRoll; };
if (isNull _patient) exitWith {};
if ((_patient getVariable ["ACME_hpmk_state", ""]) == "wrapped") exitWith {
    ["This patient is already wrapped in an HPMK.", 2, _medic] call ACME_fnc_netNotice;
};

[_patient, "wrapped", true, false] call ACME_fnc_hpmkStateCommit;
_patient setVariable ["ACME_hpmk_lastTickLocal", CBA_missionTime, false];
if (isNil "ACME_hpmk_activePatients") then { ACME_hpmk_activePatients = []; };
ACME_hpmk_activePatients pushBackUnique _patient;

// HPMK's own roll is allowed when the procedure needs it, but obtundation never adds a special posture writer.
private _anim = missionNamespace getVariable ["ACME_hpmk_patientAnim", "AinjPpneMstpSnonWrflDnon_rolltoback"];
if (alive _patient && {_anim != ""} && {isNull objectParent _patient}) then {
    [_patient, _anim, 1] call ACME_fnc_doAnim;
};

["Wrapped in HPMK.", 3, _medic] call ACME_fnc_netNotice;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "Wrapped in NAR HPMK", []] call ace_medical_treatment_fnc_addToLog;
};
