// limb and head direct pressure. it is one-handed and not a full maneuver: the medic can continue medical care
// while stationary. when they settle, meaning idle for about 0.8 s while looking toward the patient, the tick,
// fn_directPressurePose, drops them into the holding pose. Movement yields the pose but keeps Direct Pressure active,
// so the hold reapplies after the provider stops and settles again.
// because it does not set ACM_core_ContinuousAction_Active, the medic can continue every other medical action
// while the one-handed hold remains active. RMB and esc release manually. clotting still progresses on a timer.
params ["_medic", "_patient", "_bodyPart"];

_medic setVariable ["ACME_DP_Active", true, true];
_medic setVariable ["ACME_DP_Patient", _patient, true];
_medic setVariable ["ACME_DP_Part", _bodyPart];
_medic setVariable ["ACME_DP_Mode", "limb"];
_medic setVariable ["ACME_DP_Start", CBA_missionTime];
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 15];
_medic setVariable ["ACME_DP_Paused", false];
_medic setVariable ["ACME_DP_InPose", false];
_medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
_medic setVariable ["ACME_DP_LastPos", getPosASL _medic];
_medic setVariable ["ACME_DP_LastPoseAssert", 0];
_patient setVariable ["ACME_DP_LimbMedic", _medic, true];

// the pain stimulus: direct pressure over a fractured limb is severe. it runs on the patient owner, so the ACE pain
// and wake-state changes are local-authoritative. it is edge-triggered and cooldown-gated inside the handler.
if ([_patient, _bodyPart] call ACME_fnc_directPressureHasFracture) then {
    ["ACME_DP_fracturePain", [_patient, _bodyPart, _medic], _patient] call CBA_fnc_targetEvent;
};

if (dialog) then { closeDialog 0; };

// Enter the held pressure pose directly. Direct Pressure deliberately does NOT call medicAnimationPrep or any
// weapon-selection function. The player's selected weapon is left alone; the held CfgMoves state supplies the
// temporary treatment pose and movement/treatment input is allowed to supersede it normally.
if (isNull objectParent _medic) then {
    _medic setUnitPos "MIDDLE";
    _medic setVariable ["ACME_DP_PoseToken", (_medic getVariable ["ACME_DP_PoseToken", 0]) + 1];
    _medic setVariable ["ACME_DP_PoseGraceUntil", CBA_missionTime + 0.9];
    [_medic, "ACME_DirectPressureHold", 1.1, 1] call ACME_fnc_doAnimHeld;
    _medic setVariable ["ACME_DP_InPose", true];
    _medic setVariable ["ACME_DP_LastPoseAssert", CBA_missionTime];
};

// the manual release: RMB or esc. there is no persistent mouse hint, because the provider is not in an exclusive
// maneuver lock.
private _ids = [];
_ids pushBack ([0x01, [false,false,false], { [false] call ACME_fnc_directPressureStop; }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF1, [false,false,false], { [false] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_medic setVariable ["ACME_DP_KeyIDs", _ids];

// _bodyPart is the raw internal string. it used to go straight into the hint and the log, so both read
// "leftarm". wrong in both registers, so the display name is unconditional; the log takes the abbreviation,
// which falls back to the display name outside hardcore.
private _partName = if (_bodyPart isEqualTo "") then { "the patient" } else {
    [_bodyPart, "display"] call ACME_fnc_bodyPartName
};
private _partShort = [_bodyPart, "abbr"] call ACME_fnc_bodyPartName;
[_patient, "activity",
 "%1 started Direct pressure on %2",
 "%1 started Direct pressure on %2",
 [[_medic, false, true] call ace_common_fnc_getName, _partShort]] call ACME_fnc_medLog;

// 20 Hz while active so movement escape and idle-to-pose reapplication stay responsive. Clotting remains time-gated.
private _pfh = [ACME_fnc_directPressureTick, 0.05, [_medic, _patient, _bodyPart, "limb"]] call CBA_fnc_addPerFrameHandler;
_medic setVariable ["ACME_DP_PFH", _pfh];
