// Torso direct pressure is a true active maneuver, matching ACM's BVM/CPR interaction model.
// It closes the medical menu, owns ACM's continuous-action gate while held, and is released by ESC/RMB/H,
// provider movement, distance break, incapacitation, or an explicit stop. Limb/head pressure remains the freer
// resumable mode and does not take this continuous-action lock.
params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {};

// Do not stomp another continuous maneuver. The direct-pressure treatment itself has already finished by the time
// this callback runs, so an active gate here belongs to BVM/CPR/another ACM maneuver.
if (missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]) exitWith {
    ["Another active maneuver is already in progress.", 2, _medic] call ace_common_fnc_displayTextStructured;
    [true, _medic, false] call ACME_fnc_directPressureStop;
};

_medic setVariable ["ACME_DP_Active", true, true];
_medic setVariable ["ACME_DP_Patient", _patient, true];
_medic setVariable ["ACME_DP_Part", _bodyPart];
_medic setVariable ["ACME_DP_Mode", "torso"];
_medic setVariable ["ACME_DP_Start", CBA_missionTime];
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 15];
_medic setVariable ["ACME_DP_Paused", false];
_medic setVariable ["ACME_DP_InPose", false];
_medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
_medic setVariable ["ACME_DP_LastPos", getPosASL _medic];
_medic setVariable ["ACME_DP_LastPoseAssert", 0];
_medic setVariable ["ACME_DP_OwnsContinuous", true];
_patient setVariable ["ACME_DP_TorsoMedic", _medic, true];

// Claim the same global maneuver gate used by ACM continuous actions. This is deliberately torso-only.
missionNamespace setVariable ["ACM_core_ContinuousAction_IsDialog", false];
missionNamespace setVariable ["ACM_core_ContinuousAction_ShouldReopen", false];
missionNamespace setVariable ["ACM_core_ContinuousAction_Active", true];
missionNamespace setVariable ["ace_medical_gui_pendingReopen", false];

if (dialog) then {closeDialog 0;};

// Enter the connected two-handed pressure hold directly. No scripted weapon draw/holster cycle is introduced.
if (isNull objectParent _medic) then {
    _medic setUnitPos "MIDDLE";
    _medic setVariable ["ACME_DP_PoseToken", (_medic getVariable ["ACME_DP_PoseToken", 0]) + 1];
    _medic setVariable ["ACME_DP_PoseGraceUntil", CBA_missionTime + 0.15];
    [_medic, "ACME_DirectPressureHold", 1.1, 1] call ACME_fnc_doAnimHeld;
    _medic setVariable ["ACME_DP_InPose", true];
    _medic setVariable ["ACME_DP_LastPoseAssert", CBA_missionTime];
};

["", "Stop", "Pause / assess"] call ace_interaction_fnc_showMouseHint;

// ESC/RMB end the maneuver. H ends it and returns to the casualty menu. MMB keeps the existing assessment toggle.
private _ids = [];
_ids pushBack ([0x01, [false,false,false], { [false, ACE_player, true] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF1, [false,false,false], { [false, ACE_player, true] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0x23, [false,false,false], { [false, ACE_player, true] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF2, [false,false,false], { call ACME_fnc_directPressureAssess; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_medic setVariable ["ACME_DP_KeyIDs", _ids];

[_patient, "activity", "%1 started Direct pressure on %2", "%1 started Direct pressure on %2", [[_medic, false, true] call ace_common_fnc_getName, ([_bodyPart, "abbr"] call ACME_fnc_bodyPartName)]] call ACME_fnc_medLog;

// Every frame rather than 20 Hz. Movement intent must release the hold before the looping CfgMoves state can eat
// the first movement input.
private _pfh = [ACME_fnc_directPressureTick, 0, [_medic, _patient, _bodyPart, "torso"]] call CBA_fnc_addPerFrameHandler;
_medic setVariable ["ACME_DP_PFH", _pfh];
