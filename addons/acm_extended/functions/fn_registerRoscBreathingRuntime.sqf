// ROSC gasp. on a successful return of spontaneous circulation the patient gasps and takes a deep breath.
// ACM's attemptrosc fires ace_medical_CPRSucceeded patient-locally on success, and CPR, defib, adenosine and
// reversible-arrest resolution all route through it, so this one hook covers every ROSC path. ACE's positional
// say3d plays it to nearby players, which mirrors ACM's own wake-up sound flow. the pain moan stays suppressed
// for a few seconds so it does not stack on the gasp.
["ace_medical_CPRSucceeded", {
    params ["_patient"];
    if (isNull _patient || {!alive _patient} || {!local _patient}) exitWith {};
    // rosc_time zero-divisor fix at the source. ACM's own cprsucceeded handler stamps rosc_time to exactly
    // CBA_missionTime, and its updateheartrate then divides by CBA_missionTime minus rosc_time, which is zero on
    // this frame. this nudges the stamp a little into the past, so the divisor is never zero for any consumer, not
    // the heart rate path alone. it sits before the early exits below so it always runs.
    // CBA handlers fire in registration order. if ours ever runs before ACM's, ACM re-stamps and undoes this. the
    // guard inside our updateheartrate wrapper covers that case, because it runs immediately before the division
    // and cannot be ordered wrong.
    private _roscT = _patient getVariable ["ACM_circulation_ROSC_Time", -45];
    if (_roscT isEqualType 0 && {_roscT >= CBA_missionTime}) then {
        [_patient, [["roscTime", CBA_missionTime - 0.25]], true] call ACM_circulation_fnc_setRuntimeState;
    };
    // B18: an arrest does not bank an awake-paralysis sympathetic surge that detonates on the ROSC frame.
    [_patient,
        CBA_missionTime + (missionNamespace getVariable ["ACME_roc_postROSCStressDelay", 15]),
        0, 0, -1, true, false
    ] call ACME_fnc_rocStressStateCommit;
    _patient setVariable ["ACME_vent_fightHRAdjust", 0, true];
    _patient setVariable ["ACME_vent_fightResistAdjust", 0, true];
    [_patient, [["soundTimeoutMoan", CBA_missionTime + 10, false]]] call ACM_core_fnc_setAceMedicalState;
    private _distance = 20;
    private _targets = allPlayers inAreaArray [ASLToAGL getPosASL _patient, _distance, _distance, 0, false, _distance];
    if (_targets isEqualTo []) exitWith {};
    ["ACME_breathSay3D", [_patient, "ACME_RoscGasp", _distance], _targets] call CBA_fnc_targetEvent;
    // post-ROSC ataxic, or biot's, respirations. irregular audible breath clusters start 8 s after the gasp and
    // run until SpO2 recovers to 80 percent. they pause while a medic bags the patient.
    [_patient, "biot"] call ACME_fnc_breathSoundsStart;
}] call CBA_fnc_addEventHandler;
