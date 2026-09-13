// torso direct pressure. It uses the stronger two-handed hold pose, but it is not an exclusive ACM continuous
// maneuver: the provider may still open the medical menu and perform another intervention. The pose yields while
// an ACE treatment is active and resumes only after the provider settles again. Movement yields the pose without
// ending Direct Pressure. RMB/ESC and the medical-menu Stop action release pressure; MMB pauses to assess bleeding.
params ["_medic", "_patient", "_bodyPart"];

_medic setVariable ["ACME_DP_Active", true, true];
_medic setVariable ["ACME_DP_Patient", _patient, true];
_medic setVariable ["ACME_DP_Part", _bodyPart];
_medic setVariable ["ACME_DP_Mode", "torso"];
_medic setVariable ["ACME_DP_Start", CBA_missionTime];
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 15];  // first clot attempt at 15 s
_medic setVariable ["ACME_DP_Paused", false];
_medic setVariable ["ACME_DP_InPose", false];
_medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
_medic setVariable ["ACME_DP_LastPos", getPosASL _medic];
_medic setVariable ["ACME_DP_LastPoseAssert", 0];
_patient setVariable ["ACME_DP_TorsoMedic", _medic, true];

if (dialog) then { closeDialog 0; };

// Enter the connected pressure hold directly. Do not call medicAnimationPrep and do not ask ACE to change the
// selected weapon. The Direct Pressure CfgMoves state owns only the temporary body pose; the weapon selection is
// left untouched so there is no scripted draw/holster pre-animation before hands go to the patient.
if (isNull objectParent _medic) then {
    _medic setUnitPos "MIDDLE";
    _medic setVariable ["ACME_DP_PoseToken", (_medic getVariable ["ACME_DP_PoseToken", 0]) + 1];
    _medic setVariable ["ACME_DP_PoseGraceUntil", CBA_missionTime + 0.9];
    [_medic, "ACME_DirectPressureHold", 1.1, 1] call ACME_fnc_doAnimHeld;
    _medic setVariable ["ACME_DP_InPose", true];
    _medic setVariable ["ACME_DP_LastPoseAssert", CBA_missionTime];
};

// the mouse hints, as [lmb, RMB, MMB].
["", "Stop", "Pause / assess"] call ace_interaction_fnc_showMouseHint;

// the key handlers: esc and RMB stop, and MMB assesses. 0xf1 is RMB and 0xf2 is MMB.
private _ids = [];
_ids pushBack ([0x01, [false,false,false], { [false] call ACME_fnc_directPressureStop; }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF1, [false,false,false], { [false] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF2, [false,false,false], { call ACME_fnc_directPressureAssess; }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_medic setVariable ["ACME_DP_KeyIDs", _ids];

[_patient, "activity", "%1 started Direct pressure on %2", "%1 started Direct pressure on %2", [[_medic, false, true] call ace_common_fnc_getName, ([_bodyPart, "abbr"] call ACME_fnc_bodyPartName)]] call ACME_fnc_medLog;

// 20 Hz while active so movement escape and idle-to-pose reapplication are immediate while clotting stays time-gated.
private _pfh = [ACME_fnc_directPressureTick, 0.05, [_medic, _patient, _bodyPart, "torso"]] call CBA_fnc_addPerFrameHandler;
_medic setVariable ["ACME_DP_PFH", _pfh];
