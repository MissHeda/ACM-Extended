#include "..\script_component.hpp"
#include "..\HeadTilt_defines.hpp"
/*
 * Author: Blue
 * Perform head tilt-chin lift maneuver on patient
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call ACM_airway_fnc_beginHeadTiltChinLift;
 *
 * Public: No
 */

params ["_medic", "_patient"];

if (_patient getVariable [QGVAR(HeadTilt_State), false]) exitWith {
    [LLSTRING(HeadTiltChinLift_Already), 2, _medic] call ACEFUNC(common,displayTextStructured);
};

[[_medic, _patient, "head"], { // On Start
    params ["_medic", "_patient", "_bodyPart"];

    "ACM_HeadTilt" cutRsc ["RscHeadTilt", "PLAIN", 0, false];

    // B127: the mouse cancel belongs to the continuous-action generation which accepted this maneuver. Remove any
    // stranded old handler first, then make the new one harmless as soon as another continuous action takes over.
    private _oldID = missionNamespace getVariable [QGVAR(HeadTiltCancel_MouseID), -1];
    if (_oldID >= 0) then {[_oldID, "keydown"] call CBA_fnc_removeKeyHandler;};
    private _epoch = missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", -1];
    private _cancelCode = compile format [
        "if ((missionNamespace getVariable ['ACM_core_ContinuousAction_Epoch', -2]) == %1) then {missionNamespace setVariable ['ACM_core_ContinuousAction_Active', false];}; false",
        _epoch
    ];
    GVAR(HeadTiltCancel_MouseID) = [0xF0, [false, false, false], _cancelCode, "keydown", "", false, 0] call CBA_fnc_addKeyHandler;

    [ACELLSTRING(common,Cancel), "", ""] call ACEFUNC(interaction,showMouseHint);
    [_patient, "activity", LSTRING(HeadTiltChinLift_ActionLog), [[_medic, false, true] call ACEFUNC(common,getName)]] call ACEFUNC(medical_treatment,addToLog);
    [LLSTRING(HeadTiltChinLift_ActionHint), 2, _medic] call ACEFUNC(common,displayTextStructured);
    
    private _display = uiNamespace getVariable ["ACM_HeadTilt", displayNull];
    private _ctrlText = _display displayCtrl IDC_HEADTILT_TEXT;

    _ctrlText ctrlSetText ([_patient, false, true] call ACEFUNC(common,getName));

    _patient setVariable [QGVAR(HeadTilt_State), true, true];
}, { // On cancel
    params ["_medic", "_patient", "_bodyPart"];

    private _id = missionNamespace getVariable [QGVAR(HeadTiltCancel_MouseID), -1];
    if (_id >= 0) then {[_id, "keydown"] call CBA_fnc_removeKeyHandler;};
    GVAR(HeadTiltCancel_MouseID) = -1;

    ["", "", ""] call ACEFUNC(interaction,showMouseHint);

    "ACM_HeadTilt" cutText ["","PLAIN", 0, false];

    [LLSTRING(HeadTiltChinLift_ActionCancelled), 1.5, _medic] call ACEFUNC(common,displayTextStructured);

    if !(_patient getVariable [QGVAR(RecoveryPosition_State), false]) then {
        _patient setVariable [QGVAR(HeadTilt_State), false, true];
    };
}, { // PerFrame
    params ["_medic", "_patient", "_bodyPart"];

    if (_patient getVariable [QGVAR(AirwayItem_Oral), ""] == "SGA" || _patient getVariable [QGVAR(SurgicalAirway_InProgress), false] || _patient getVariable [QGVAR(SurgicalAirway_State), false] || _patient getVariable [QGVAR(RecoveryPosition_State), false] || _patient call ACEFUNC(common,isBeingDragged) || _patient call ACEFUNC(common,isBeingCarried)) then {
        EGVAR(core,ContinuousAction_Active) = false;
    };
}] call EFUNC(core,beginContinuousAction);