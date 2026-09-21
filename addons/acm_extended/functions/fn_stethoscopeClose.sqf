// Unload is the final authority for this display instance.
// It must release audio, patient positioning, the continuous-action reservation and the provider's frozen pose.
// The normal controller PFH still performs the same cancellation path; every operation below is token-scoped and
// therefore safe when both paths run on adjacent frames.
disableSerialization;
params ["_display"];
if (isNull _display) exitWith {};

private _tickPFH = _display getVariable ["ACME_stethTickPFH", -1];
if (_tickPFH isEqualType 0 && {_tickPFH >= 0}) then {[_tickPFH] call CBA_fnc_removePerFrameHandler;};
_display setVariable ["ACME_stethTickPFH", -1];

{
    _x params ["_emitter","_sound"];
    if (!isNull _sound) then {deleteVehicle _sound;};
    if (!isNull _emitter) then {deleteVehicle _emitter;};
} forEach (_display getVariable ["ACME_stethChannels",[]]);
_display setVariable ["ACME_stethChannels",[]];
_display setVariable ["ACME_stethPressed",false];

private _medic = _display getVariable ["ACME_stethMedic",objNull];
private _patient = _display getVariable ["ACME_stethPatient",objNull];
private _poseEpoch = _display getVariable ["ACME_stethPoseEpoch",-1];
private _continuousEpoch = _display getVariable ["ACME_continuousEpoch",-1];

// Release this provider's casualty animation lease immediately. The normal onCancel path sees the cleared lease
// and becomes a no-op, so a missed PFH frame can never leave the patient pinned by a dead stethoscope session.
if (!isNull _medic) then {
    private _lease = _medic getVariable ["ACME_stethPatientAnimLease",[]];
    if ((count _lease) >= 2) then {
        private _leasePatient = _lease param [0,objNull];
        private _leaseToken = _lease param [1,""];
        if (!isNull _leasePatient && {_leaseToken != ""}) then {
            [_leasePatient,_leaseToken] call ACME_fnc_patientAnimRelease;
        };
    };
    _medic setVariable ["ACME_stethPatientAnimLease",[],false];

    // UseStethoscope removes the carrier before the modal scope opens. The scope display is the real lifetime
    // boundary, so release that exact lease here even if the generic controller was superseded.
    private _chestLease = _medic getVariable ["ACME_chestAccess_treatment", []];
    if ((_chestLease param [0, objNull]) isEqualTo _patient
        && {toLowerANSI (_chestLease param [1, ""]) == "usestethoscope"}) then {
        private _leaseId = _chestLease param [2, ""];
        _medic setVariable ["ACME_chestAccess_treatment", []];
        if (!isNull _patient && {_leaseId != ""}) then {
            [_patient, _medic, _leaseId, false, "usestethoscope"] call ACME_fnc_chestAccessVestEvent;
        };
    };
};

// Retire only the continuous-action generation that created this display. This is the critical fallback for
// abnormal dialog teardown: a dead stethoscope display must never leave ACM_core_ContinuousAction_Active stuck true.
if (_continuousEpoch >= 0
    && {(missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch",-2]) == _continuousEpoch}) then {
    ACM_core_ContinuousAction_Active = false;
};

// Release only the exact stethoscope treatment-pose generation. treatmentPoseStop restores animSpeedCoef,
// clears the remote/JIP hold and returns the provider through the move graph.
if (!isNull _medic && {_poseEpoch >= 0}
    && {(_medic getVariable ["ACME_treatmentPoseEpoch",-2]) == _poseEpoch}) then {
    [_medic,"stethoscope",_poseEpoch] call ACME_fnc_treatmentPoseStop;

    // A malformed/partially-cleared pose record used to make treatmentPoseStop return before the speed reset.
    // Because the exact pose epoch still belongs to this closed scope, it is safe to repair that one orphan here.
    if (local _medic && {getAnimSpeedCoef _medic == 0}) then {
        _medic setAnimSpeedCoef 1;
    };
    if (local _medic
        && {toLowerANSI animationState _medic == "acme_stethoscopework"}
        && {!([_medic] call ACME_fnc_animBlocked)}) then {
        _medic setUnitPos "MIDDLE";
        [_medic,"AmovPknlMstpSnonWnonDnon",1] call ACME_fnc_doAnim;
    };
};

if ((uiNamespace getVariable ["ACM_breathing_Stethoscope_DLG",displayNull]) isEqualTo _display) then {
    uiNamespace setVariable ["ACM_breathing_Stethoscope_DLG",displayNull];
};
[-1] call ace_hearing_fnc_updateHearingProtection;