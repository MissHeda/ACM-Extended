/*
 * Author: Blue
 * Handle using stethoscope on chest.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call ACM_breathing_fnc_useStethoscope;
 *
 * Public: No
 */

params ["_medic", "_patient", ["_bodyPart", "Body"]];

// you cannot auscultate in an airframe.
// this is not a balance decision, it is simply true, and every flight medic knows it. a running helicopter puts 500
// to 2000 hz of transmission and gear-mesh noise straight through the structure, right on top of the frequencies
// breath sounds live in. you are not listening to a quiet chest through a stethoscope, you are listening to a
// gearbox. crews do not even try: they go to what they can see and measure, meaning the chest rise, the EtCO2, the
// SpO2 and the numbers of the ventilator.
// the refusal is the lesson: the tools you leaned on in the aid station do not all come with you, and the ones that
// do are the ones with a screen.
// the exitwith is top-level on purpose. nested inside an if or else it would only exit the inner block and the
// stethoscope would carry on working regardless, which is exactly the sort of silent no-op that is impossible to
// spot from the outside.
private _mVeh = vehicle _medic;
if ((missionNamespace getVariable ["ACME_flightNoise_enable", true])
    && {_mVeh != _medic}
    && {_mVeh isKindOf "Air"}
    && {isEngineOn _mVeh}) exitWith {
    ["Cannot auscultate: airframe noise. Use EtCO2, SpO2 and chest rise.", 3, _medic] call ace_common_fnc_displayTextStructured;
};

[_patient, "activity", "STR_ACM_breathing_Stethoscope_ActionLog", [[_medic, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;

[[_medic, _patient, _bodyPart], {  // on start.
    params ["_medic", "_patient", "_bodyPart"];

    [_patient] call ACM_breathing_fnc_updateLungState;  // todo: this probably needs moving.

    // Auscultation gets one owner-authoritative patient pose lease for the whole scope session. Elevated and
    // otherwise downed casualties are held directly in the normal face-up rest. There is deliberately no
    // roll-to-back transition here: head elevation already ran its authored lowering sequence before this dialog
    // opened, and an ordinary downed casualty can go straight to the supine rest without the sideways roll theatre.
    // A conscious upright casualty who was not already positioned is not forced to the ground.
    private _lyingRaw = _patient getVariable ["ACM_core_Lying_State", false];
    private _lying = if (_lyingRaw isEqualType true) then {_lyingRaw} else {_lyingRaw > 0};
    private _needsSupine = (_patient getVariable ["ACE_isUnconscious", false])
        || {_patient getVariable ["ace_medical_unconscious", false]}
        || {_lying}
        || {_patient getVariable ["ACME_headElevated", false]}
        || {_patient getVariable ["ACME_headElev_Suspended", false]}
        || {(stance _patient) == "PRONE"};
    if (_needsSupine && {isNull objectParent _patient}) then {
        private _serial = (missionNamespace getVariable ["ACME_stethPatientAnimSerial", 0]) + 1;
        missionNamespace setVariable ["ACME_stethPatientAnimSerial", _serial];
        private _token = format ["steth:%1:%2:%3:%4", clientOwner, netId _medic, netId _patient, _serial];
        private _faceUp = missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"];
        private _anim = ["", _faceUp] select ((toLowerANSI animationState _patient) != (toLowerANSI _faceUp));
        [_patient, _anim, 2, "stethoscope", _medic, 1.6, 4, _token] call ACME_fnc_patientAnimRequest;
        _medic setVariable ["ACME_stethPatientAnimLease", [_patient, _token, CBA_missionTime + 0.65], false];
    } else {
        _medic setVariable ["ACME_stethPatientAnimLease", [], false];
    };

    ACM_breathing_Stethoscope_BellMoving = false;
    ACM_breathing_Stethoscope_NextBreath = -1;
    ACM_breathing_Stethoscope_NextBeat = -1;

    ACM_breathing_Stethoscope_BreathSoundID = -1;
    ACM_breathing_Stethoscope_BeatSoundID = -1;

    ace_hearing_volumeAttenuation = 0.2;
    [(localize "STR_ACE_Volume_Lowered"), 1.5, _medic] call ace_common_fnc_displayTextStructured;

    createDialog "ACM_breathing_Stethoscope_Dialog";

    uiNamespace setVariable ["ACM_breathing_Stethoscope_DLG",(findDisplay 81000)];

    private _display = uiNamespace getVariable ["ACM_breathing_Stethoscope_DLG", displayNull];
    private _ctrlText = _display displayCtrl 81001;
    _ctrlText ctrlSetText format ["%1 (%2)", [_patient, false, true] call ace_common_fnc_getName, (localize "STR_ACE_medical_gui_Torso")];
}, {  // on cancel.
    params ["_medic", "_patient", "_bodyPart"];

    // Release only this provider's animation token. A second provider auscultating the same casualty keeps their
    // own lease and therefore cannot be interrupted by this dialog closing.
    private _lease = _medic getVariable ["ACME_stethPatientAnimLease", []];
    if ((count _lease) >= 2) then {
        private _leasePatient = _lease param [0, objNull];
        private _leaseToken = _lease param [1, ""];
        if (!isNull _leasePatient && {_leaseToken != ""}) then {
            [_leasePatient, _leaseToken] call ACME_fnc_patientAnimRelease;
        };
    };
    _medic setVariable ["ACME_stethPatientAnimLease", [], false];

    stopSound ACM_breathing_Stethoscope_BreathSoundID;
    stopSound ACM_breathing_Stethoscope_BeatSoundID;

    if !(isNull findDisplay 81000) then {
        closeDialog 0;
    };

    ["STR_ACM_breathing_Stethoscope_Stopped", 1.5, _medic] call ace_common_fnc_displayTextStructured;

    [-1] call ace_hearing_fnc_updateHearingProtection;
}, {  // per frame.
    params ["_medic", "_patient", "_bodyPart"];

    // CPR is a higher-order chest maneuver. If another provider starts compressions, retire auscultation instead
    // of letting the two procedures fight over the patient.
    if ([_patient] call ACM_core_fnc_cprActive) exitWith {
        ACM_core_ContinuousAction_Active = false;
    };

    // Refresh the lease without replaying an animation when the casualty is already face-up. This is the critical
    // multiplayer guard: repeated providers may request the same posture, but only the current owner token can
    // refresh it, and no 0.6-second animation restart loop is created under the auscultation camera.
    private _lease = _medic getVariable ["ACME_stethPatientAnimLease", []];
    if ((count _lease) >= 3 && {CBA_missionTime >= (_lease param [2, 0])}) then {
        private _leasePatient = _lease param [0, objNull];
        private _leaseToken = _lease param [1, ""];
        if (!isNull _leasePatient && {_leasePatient isEqualTo _patient} && {_leaseToken != ""}) then {
            private _faceUp = missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"];
            private _anim = ["", _faceUp] select ((toLowerANSI animationState _patient) != (toLowerANSI _faceUp));
            [_patient, _anim, 2, "stethoscope", _medic, 1.6, 4, _leaseToken] call ACME_fnc_patientAnimRequest;
            _lease set [2, CBA_missionTime + 0.65];
            _medic setVariable ["ACME_stethPatientAnimLease", _lease, false];
        };
    };

    private _display = uiNamespace getVariable ["ACM_breathing_Stethoscope_DLG", displayNull];
    private _ctrlBell = _display displayCtrl 81002;
    private _ctrlBellCenter = [(((ctrlPosition _ctrlBell) select 0) + (((ctrlPosition _ctrlBell) select 2) / 2)), (((ctrlPosition _ctrlBell) select 1) + (((ctrlPosition _ctrlBell) select 3) / 2))];

    private _ctrlRightLungSpace = ctrlPosition (_display displayCtrl 81010);
    private _ctrlRightLungSpace2 = ctrlPosition (_display displayCtrl 81011);
    private _rightLungProximity = ([_ctrlRightLungSpace, _ctrlBellCenter] call ACM_GUI_fnc_inZone) || ([_ctrlRightLungSpace2, _ctrlBellCenter] call ACM_GUI_fnc_inZone);

    private _ctrlLeftLungSpace = ctrlPosition (_display displayCtrl 81012);
    private _ctrlLeftLungSpace2 = ctrlPosition (_display displayCtrl 81013);
    private _leftLungProximity = ([_ctrlLeftLungSpace, _ctrlBellCenter] call ACM_GUI_fnc_inZone) || ([_ctrlLeftLungSpace2, _ctrlBellCenter] call ACM_GUI_fnc_inZone);

    private _ctrlRightLungPoint_Bronchial = ctrlPosition (_display displayCtrl 81014);
    private _ctrlRightLungPoint_BronchoVesticular = ctrlPosition (_display displayCtrl 81015);
    private _ctrlRightLungPoint_VesticularMiddle = ctrlPosition (_display displayCtrl 81016);
    private _ctrlRightLungPoint_VesticularLower = ctrlPosition (_display displayCtrl 81017);

    private _ctrlLeftLungPoint_Bronchial = ctrlPosition (_display displayCtrl 81019);
    private _ctrlLeftLungPoint_BronchoVesticular = ctrlPosition (_display displayCtrl 81020);
    private _ctrlLeftLungPoint_VesticularMiddle = ctrlPosition (_display displayCtrl 81021);
    private _ctrlLeftLungPoint_VesticularLower = ctrlPosition (_display displayCtrl 81022);

    private _ctrlRightSide = ctrlPosition (_display displayCtrl 81003);
    private _ctrlLeftSide = ctrlPosition (_display displayCtrl 81004);

    private _activeChestSide = switch (true) do {
        case ([_ctrlRightSide, _ctrlBellCenter] call ACM_GUI_fnc_inZone): {0};
        case ([_ctrlLeftSide, _ctrlBellCenter] call ACM_GUI_fnc_inZone): {1};
        default {-1};
    };

    private _activeLungListeningPoint = -1;
    private _lungLoudness = 0;

    if (_activeChestSide > -1) then {
        _lungLoudness = [0.02, 0.25] select (_rightLungProximity || _leftLungProximity);

        {
            if ([_x, _ctrlBellCenter] call ACM_GUI_fnc_inZone) then {
                _activeLungListeningPoint = _forEachIndex;
                break;
            };
        } forEach ([[_ctrlRightLungPoint_Bronchial, _ctrlRightLungPoint_BronchoVesticular, _ctrlRightLungPoint_VesticularMiddle, _ctrlRightLungPoint_VesticularLower], [_ctrlLeftLungPoint_Bronchial, _ctrlLeftLungPoint_BronchoVesticular, _ctrlLeftLungPoint_VesticularMiddle, _ctrlLeftLungPoint_VesticularLower]] select _activeChestSide);
    };

    private _ctrlHeartPoint_1 = ctrlPosition (_display displayCtrl 81030);
    private _ctrlHeartPoint_2 = ctrlPosition (_display displayCtrl 81031);
    private _ctrlHeartPoint_3 = ctrlPosition (_display displayCtrl 81032);
    private _ctrlHeartPoint_4 = ctrlPosition (_display displayCtrl 81033);

    private _activeHeartListeningPoint = -1;
    {
        if ([_x, _ctrlBellCenter] call ACM_GUI_fnc_inZone) then {
            _activeHeartListeningPoint = _forEachIndex;
            break;
        };
    } forEach [_ctrlHeartPoint_1,_ctrlHeartPoint_2,_ctrlHeartPoint_3,_ctrlHeartPoint_4];

    private _ctrlHeartCenter = ctrlPosition (_display displayCtrl 81034);
    private _ctrlHeartCenterPoint = [((_ctrlHeartCenter select 0) + ((_ctrlHeartCenter select 2) / 2)), ((_ctrlHeartCenter select 1) + ((_ctrlHeartCenter select 3) / 2))];

    private _heartCenterDistance = (_ctrlHeartCenterPoint distance2D _ctrlBellCenter);
    private _heartLoudness = (linearConversion [0.36, 0.1, _heartCenterDistance, 0.03, 0.5, true]);

    private _ctrlBoneSpace_Sternum = ctrlPosition (_display displayCtrl 81040);

    private _boneProximity = [_ctrlBoneSpace_Sternum, _ctrlBellCenter] call ACM_GUI_fnc_inZone;

    if (ACM_breathing_Stethoscope_BellMoving) then {
        getMousePosition params ["_mouseX", "_mouseY"];

        (ctrlPosition _ctrlBell) params ["","","_bellW","_bellH"];

        _ctrlBell ctrlSetTooltip (localize "STR_ACM_breathing_Stethoscope_PlaceBell");

        _ctrlBell ctrlSetPosition [_mouseX - (_bellW / 2), _mouseY - (_bellH / 2), _bellW, _bellH];
        _ctrlBell ctrlCommit 0;

        if (ACM_breathing_Stethoscope_BeatSoundID != -1) then {
            stopSound ACM_breathing_Stethoscope_BeatSoundID;
            ACM_breathing_Stethoscope_BeatSoundID = -1;
        };

        if (ACM_breathing_Stethoscope_BreathSoundID != -1) then {
            stopSound ACM_breathing_Stethoscope_BreathSoundID;
            ACM_breathing_Stethoscope_BreathSoundID = -1;
        };
    } else {
        _ctrlBell ctrlSetTooltip (localize "STR_ACM_breathing_Stethoscope_MoveBell");

        private _HR = (_patient getVariable ["ace_medical_heartRate", 80]);
        private _RR = (_patient getVariable ["ACM_breathing_RespirationRate", 18]);

        if (_HR > 0 && alive _patient) then {
            if (ACM_breathing_Stethoscope_NextBeat < CBA_missionTime) then {
                private _heartBeatDelay = 60 / _HR;
                ACM_breathing_Stethoscope_NextBeat = CBA_missionTime + _heartBeatDelay;

                private _variant = 1 + (round (random 2));
                private _rate = switch (true) do {
                    case (_heartBeatDelay < 0.5): {
                        "Fast";
                    };
                    case (_heartBeatDelay > 1.2): {
                        "Slow";
                    };
                    default {
                        "Normal";
                    };
                };

                _heartLoudness = [_heartLoudness, 0.95] select (_activeHeartListeningPoint > -1);
                _heartLoudness = [_heartLoudness, (_heartLoudness min 0.1)] select _boneProximity;

                ACM_breathing_Stethoscope_BeatSoundID = playSoundUI [(format ["ACM_Stethoscope_HeartBeat_%1_%2", _rate, _variant]), _heartLoudness, (1 + (random 0.1)), false];
            };
            if (_RR < 1) exitWith {};
            if (ACM_breathing_Stethoscope_NextBreath < CBA_missionTime) then {
                private _breathDelay = 60 / _RR;
                ACM_breathing_Stethoscope_NextBreath = CBA_missionTime + _breathDelay;

                if (_activeHeartListeningPoint > -1) exitWith {};
                if (_activeChestSide == -1) exitWith {};

                private _volumeModifier = 1;

                // ACME: over-resuscitation pulmonary edema. ACM only refreshes the stored lungstate on chest-trauma events, so a
                // patient who is purely over-resuscitated, with no ptx or htx, never gets it set. read the live Overload_Volume
                // here so auscultation always reflects the current edema. a real injury state, 1 or 2, on this side still takes
                // precedence.
                private _lungSideState = (_patient getVariable ["ACM_breathing_Stethoscope_LungState", [0,0]]) select _activeChestSide;
                if (_lungSideState == 0) then {
                    private _crackleFlag = _patient getVariable ["ACME_edema_crackles", false];
                    private _overload = _patient getVariable ["ACM_circulation_Overload_Volume", 0];
                    if (_crackleFlag || {_overload > (missionNamespace getVariable ["ACME_edema_threshold", 0.5])}) then {
                        _lungSideState = 3;
                    };
                };

                private _type = switch (_lungSideState) do {
                    case 1: {
                        _volumeModifier = 0.8;
                        "Shallow";
                    };
                    case 2: {
                        _volumeModifier = 0.3;
                        "Dull";
                    };
                    // ACME: over-resuscitation pulmonary edema gives wet crackles.
                    case 3: {
                        _volumeModifier = 1;
                        "Crackles";
                    };
                    default {
                        "Normal";
                    };
                };
                private _rate = switch (true) do {
                    // ACME: the crackle rate for over-resuscitation edema keys off the edema severity, ACM's Overload_Volume, rather
                    // than the measured rr, which an ACM-final function owns and we cannot reliably raise. heavy edema gives fast
                    // crackles and milder edema gives normal crackles, so both crackle variants have a real trigger.
                    case (_lungSideState == 3): {
                        private _ov = _patient getVariable ["ACM_circulation_Overload_Volume", 0];
                        if (_ov >= (missionNamespace getVariable ["ACME_edema_crackleFastVol", 0.5])) then {"Fast"} else {"Normal"};
                    };
                    case (_breathDelay < 2): {
                        "Fast";
                    };
                    case (_breathDelay > 5): {
                        "Slow";
                    };
                    default {
                        "Normal";
                    };
                };

                _lungLoudness = [_lungLoudness, 0.95] select (_activeLungListeningPoint > -1);
                _lungLoudness = [_lungLoudness, (_lungLoudness min 0.1)] select _boneProximity;

                ACM_breathing_Stethoscope_BreathSoundID = playSoundUI [(format ["ACM_Stethoscope_Breath_%1_%2", _rate, _type]), (_lungLoudness * _volumeModifier), 1, false];
            };
        };
    };
}, false, 81000] call ACME_fnc_beginStethoscopeAction;
