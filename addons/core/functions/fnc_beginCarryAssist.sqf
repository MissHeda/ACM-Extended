#include "..\script_component.hpp"
#include "..\ContinuousActionText_defines.hpp"
/*
 * Author: Blue
 * Prepare patient to be carried.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call ACM_core_fnc_beginCarryAssist;
 *
 * Public: No
 */

params ["_medic", "_patient"];

if (_patient getVariable [QGVAR(CarryAssist_State), false]) exitWith {
    [LLSTRING(AssistCarry_Already), 2, _medic] call ACEFUNC(common,displayTextStructured);
};

[[_medic, _patient, "body"], { // On Start
    params ["_medic", "_patient", "_bodyPart"];

    "ACM_ContinuousActionText" cutRsc ["RscContinuousActionText", "PLAIN", 0, false];

    // B127: this is an extra cancel key on top of beginContinuousAction's own lifetime. Make it belong to the
    // generation that actually accepted this carry-assist session. A missed old handler therefore cannot cancel a
    // later BVM/head-tilt/other continuous maneuver.
    private _oldID = missionNamespace getVariable [QGVAR(CarryAssistCancel_MouseID), -1];
    if (_oldID >= 0) then {[_oldID, "keydown"] call CBA_fnc_removeKeyHandler;};
    private _epoch = missionNamespace getVariable [QGVAR(ContinuousAction_Epoch), -1];
    private _cancelCode = compile format [
        "if ((missionNamespace getVariable ['ACM_core_ContinuousAction_Epoch', -2]) == %1) then {missionNamespace setVariable ['ACM_core_ContinuousAction_Active', false];}; false",
        _epoch
    ];
    GVAR(CarryAssistCancel_MouseID) = [0xF0, [false, false, false], _cancelCode, "keydown", "", false, 0] call CBA_fnc_addKeyHandler;

    [ACELLSTRING(common,Cancel), "", ""] call ACEFUNC(interaction,showMouseHint);
    [(format [LLSTRING(AssistCarry_Complete), ([_patient, false, true] call ACEFUNC(common,getName))]), 2, _medic] call ACEFUNC(common,displayTextStructured);

    private _display = uiNamespace getVariable ["ACM_ContinuousActionText", displayNull];
    private _ctrlTextUpper = _display displayCtrl IDC_CONTINUOUSACTIONTEXT_UPPER;
    private _ctrlTextLower = _display displayCtrl IDC_CONTINUOUSACTIONTEXT_BOTTOM;

    _ctrlTextUpper ctrlSetText LLSTRING(AssistCarry_Progress);
    _ctrlTextLower ctrlSetText ([_patient, false, true] call ACEFUNC(common,getName));

    _patient setVariable [QGVAR(CarryAssist_State), true, true];
}, { // On cancel
    params ["_medic", "_patient", "_bodyPart", "", "_notInVehicle"];

    private _id = missionNamespace getVariable [QGVAR(CarryAssistCancel_MouseID), -1];
    if (_id >= 0) then {[_id, "keydown"] call CBA_fnc_removeKeyHandler;};
    GVAR(CarryAssistCancel_MouseID) = -1;

    ["", "", ""] call ACEFUNC(interaction,showMouseHint);

    "ACM_ContinuousActionText" cutText ["","PLAIN", 0, false];

    [LLSTRING(AssistCarry_Cancelled), 1.5, _medic] call ACEFUNC(common,displayTextStructured);

    _patient setVariable [QGVAR(CarryAssist_State), false, true];
}, { // PerFrame
    params ["_medic", "_patient", "_bodyPart"];

    if (_patient call ACEFUNC(common,isBeingDragged) || _patient call ACEFUNC(common,isBeingCarried)) then {
        GVAR(ContinuousAction_Active) = false;
    };
}] call EFUNC(core,beginContinuousAction);
