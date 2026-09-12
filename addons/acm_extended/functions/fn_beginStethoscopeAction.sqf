/* B45 stethoscope-only continuous action controller.
 *
 * The scope dialog owns its own lifetime.  A provider pose ending is NOT a treatment cancellation: B44 coupled
 * those two states, so the panel disappeared with "Stopped using stethoscope" whenever the held pose retired
 * before the bell was picked up.  Normal exit is Escape, and every normal dialog close routes back to the
 * previous medical menu. H is consumed while the scope is open so it cannot silently replace the minigame.
 */
params ["_args", "_onStart", "_onCancel", "_perFrame", ["_allowProne", false], ["_dialogID", -1]];
_args params ["_medic", "_patient", "_bodyPart", ["_extraArgs", []]];

if (ACM_core_ContinuousAction_Active) exitWith {};

ACM_core_ContinuousAction_IsDialog = (_dialogID != -1);
ACM_core_ContinuousAction_Active = true;
ACM_core_ContinuousAction_ShouldReopen = false;
ace_medical_gui_pendingReopen = false;

if (dialog) then {closeDialog 0;};

private _notInVehicle = isNull objectParent _medic;

// One animation owner is enough, but its lifetime is deliberately independent from the dialog lifetime.
private _poseEpoch = [_medic, "stethoscope"] call ACME_fnc_treatmentPoseStart;
_args call _onStart;

private _dialogKeyEH = -1;
if (ACM_core_ContinuousAction_IsDialog) then {
    private _scopeDisplay = findDisplay _dialogID;
    if (!isNull _scopeDisplay) then {
        _dialogKeyEH = _scopeDisplay displayAddEventHandler ["KeyDown", {
            params ["_display", "_key"];
            // DIK_ESCAPE. Consume the native close and let the controller run one clean cancellation/reopen path.
            if (_key == 0x01) exitWith {
                ACM_core_ContinuousAction_ShouldReopen = true;
                ACM_core_ContinuousAction_Active = false;
                true
            };
            // DIK_H. The medical-menu hotkey must not replace a live stethoscope minigame.
            if (_key == 0x23) exitWith {true};
            false
        }];
    };
} else {
    ACM_core_ContinuousAction_Cancel_EscapeID = [0x01, [false, false, false], {
        ACM_core_ContinuousAction_ShouldReopen = true;
        ACM_core_ContinuousAction_Active = false;
    }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler;
};

[{
    params ["_args", "_idPFH"];
    _args params ["_medic", "_patient", "_bodyPart", "_extraArgs", "_notInVehicle", "_poseEpoch", "_perFrame", "_onCancel", "_dialogID", "_dialogKeyEH"];

    private _patientCondition = (_patient isEqualTo objNull);
    private _medicCondition = (!local _medic || !(alive _medic) || (_medic getVariable ["ACE_isUnconscious", false]) || _medic isEqualTo objNull);
    private _vehicleCondition = (objectParent _medic isNotEqualTo objectParent _patient);
    private _enteredVehicle = _notInVehicle && {!isNull objectParent _medic};
    private _distanceCondition = (_patient distance2D _medic > ace_medical_gui_maxDistance);

    private _dialogCondition = dialog;
    if (ACM_core_ContinuousAction_IsDialog) then {
        _dialogCondition = isNull (findDisplay _dialogID);
    };

    // B45: DO NOT include treatmentPoseEpisode here. Bell pickup/drag state and animation retirement cannot close
    // the scope. Only an explicit close/ESC or a genuinely invalid treatment context ends the action.
    if (_patientCondition || _medicCondition || _enteredVehicle || !ACM_core_ContinuousAction_Active || _dialogCondition
        || {(!_notInVehicle && _vehicleCondition) || {(_notInVehicle && _distanceCondition)}}) exitWith {
        [_idPFH] call CBA_fnc_removePerFrameHandler;

        if (ACM_core_ContinuousAction_IsDialog) then {
            private _d = findDisplay _dialogID;
            if (!isNull _d && {_dialogKeyEH >= 0}) then {_d displayRemoveEventHandler ["KeyDown", _dialogKeyEH];};
        } else {
            [ACM_core_ContinuousAction_Cancel_EscapeID, "keydown"] call CBA_fnc_removeKeyHandler;
        };

        // A dialog that was closed normally (ESC or UI teardown while the treatment context is still valid)
        // returns to the medical menu. Do not try to reopen for a dead/unconscious/remote medic.
        private _returnToMenu = (ACM_core_ContinuousAction_ShouldReopen || {_dialogCondition})
            && {!_patientCondition} && {!_medicCondition};

        ACM_core_ContinuousAction_Active = false;
        [_medic, "stethoscope", _poseEpoch] call ACME_fnc_treatmentPoseStop;
        [_medic, _patient, _bodyPart, _extraArgs, _notInVehicle] call _onCancel;

        ["ace_treatmentFailed", [_medic, _patient, _bodyPart, "ACM_ContinuousAction", "", "", false]] call CBA_fnc_localEvent;

        if (_returnToMenu) then {
            ["ACM_core_openMedicalMenu", _patient] call CBA_fnc_localEvent;
        };
    };

    _args call _perFrame;
}, 0, [_medic, _patient, _bodyPart, _extraArgs, _notInVehicle, _poseEpoch, _perFrame, _onCancel, _dialogID, _dialogKeyEH]] call CBA_fnc_addPerFrameHandler;
