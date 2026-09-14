// Idempotent Direct Pressure teardown for an explicit medic. Safe after distance break, death, menu stop, respawn,
// a stale PFH, movement, or a partially-started hold. The function intentionally clears only state owned by this
// Direct Pressure instance and retains a legacy cleanup path for torso holds created by older runtime code.
params [["_silent", false, [false]], ["_medic", ACE_player, [objNull]], ["_reopen", false, [false]]];
if (isNull _medic) exitWith {};

private _wasActive = _medic getVariable ["ACME_DP_Active", false];
private _patient = _medic getVariable ["ACME_DP_Patient", objNull];
private _part = _medic getVariable ["ACME_DP_Part", ""];
private _mode = _medic getVariable ["ACME_DP_Mode", ""];
private _wasInPose = _medic getVariable ["ACME_DP_InPose", false];
private _stateBefore = toLower animationState _medic;
private _ownsContinuous = _medic getVariable ["ACME_DP_OwnsContinuous", false];

// Retire every delayed Direct Pressure pose request first. ACME_DP_PoseToken belongs to the DP layer itself;
// ACME_dah_gen owns ACME_fnc_doAnimHeld's short reassert worker.
_medic setVariable ["ACME_DP_PoseToken", (_medic getVariable ["ACME_DP_PoseToken", 0]) + 1];
_medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];

private _pfh = _medic getVariable ["ACME_DP_PFH", -1];
if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
{[_x, "keydown"] call CBA_fnc_removeKeyHandler;} forEach (_medic getVariable ["ACME_DP_KeyIDs", []]);
private _d3 = _medic getVariable ["ACME_DP_Draw3D", -1];
if (_d3 >= 0) then {removeMissionEventHandler ["Draw3D", _d3];};
[] call ace_interaction_fnc_hideMouseHint;

// Compatibility cleanup for a hold started before the non-exclusive rewrite. New Direct Pressure code never sets
// ACME_DP_OwnsContinuous, so it cannot clear BVM, CPR, or another maneuver's gate.
if (_ownsContinuous) then {
    missionNamespace setVariable ["ACM_core_ContinuousAction_Active", false];
    missionNamespace setVariable ["ACM_core_ContinuousAction_IsDialog", false];
    missionNamespace setVariable ["ACM_core_ContinuousAction_ShouldReopen", false];
};

if (!isNull _patient) then {
    if ((_patient getVariable ["ACME_DP_TorsoMedic", objNull]) isEqualTo _medic) then {
        _patient setVariable ["ACME_DP_TorsoMedic", objNull, true];
    };
    if ((_patient getVariable ["ACME_DP_LimbMedic", objNull]) isEqualTo _medic) then {
        _patient setVariable ["ACME_DP_LimbMedic", objNull, true];
    };
    if (_part != "" && {(_patient getVariable [format ["ACME_DP_press_%1", _part], objNull]) isEqualTo _medic}) then {
        _patient setVariable [format ["ACME_DP_press_%1", _part], objNull, true];
    };
};

// Break only our decorative hold. Priority 2 remains a narrow safety fallback when the engine is physically still
// inside ACME_DirectPressureHold, preventing the provider from being stranded in the looping state.
private _ownsHold = _wasInPose || {_stateBefore == "acme_directpressurehold"};
if (local _medic && {alive _medic} && {isNull objectParent _medic} && {_ownsHold}) then {
    _medic setUnitPos "AUTO";
    private _exitPriority = [1, 2] select (_stateBefore == "acme_directpressurehold");
    [_medic, "AmovPknlMstpSnonWnonDnon", _exitPriority] call ACME_fnc_doAnim;
};

{
    _x params ["_name", "_value", ["_public", false]];
    _medic setVariable [_name, _value, _public];
} forEach [
    ["ACME_DP_Active", false, true],
    ["ACME_DP_Patient", objNull, true],
    ["ACME_DP_Part", ""],
    ["ACME_DP_Mode", ""],
    ["ACME_DP_Start", 0],
    ["ACME_DP_NextClot", 0],
    ["ACME_DP_Paused", false],
    ["ACME_DP_InPose", false],
    ["ACME_DP_IdleStart", 0],
    ["ACME_DP_LastPos", []],
    ["ACME_DP_PFH", -1],
    ["ACME_DP_KeyIDs", []],
    ["ACME_DP_Draw3D", -1],
    ["ACME_DP_PoseGraceUntil", 0],
    ["ACME_DP_LastPoseAssert", 0],
    ["ACME_DP_ClinicalYield", false],
    ["ACME_DP_ClinicalYieldStart", 0],
    ["ACME_DP_PauseTreatmentClass", ""],
    ["ACME_DP_TreatmentBusy", false],
    ["ACME_DP_OwnsContinuous", false]
];

if (_wasActive) then {
    if (!_silent) then {["Released direct pressure.", 1.5, _medic] call ace_common_fnc_displayTextStructured;};
    if (!isNull _patient) then {
        [_patient, "activity", "%1 stopped Direct pressure on %2", "%1 stopped Direct pressure on %2",
            [[_medic, false, true] call ace_common_fnc_getName, ([_part, "abbr"] call ACME_fnc_bodyPartName)]] call ACME_fnc_medLog;
    };
};

// Keep this only for a stale pre-rewrite torso hold that explicitly requested a reopen. New holds do not own the
// global continuous-action gate and never use this path.
if (_reopen && {_ownsContinuous} && {!isNull _patient} && {alive _medic} && {!(_medic getVariable ["ACE_isUnconscious", false])}) then {
    [{params ["_p"]; if (!isNull _p) then {["ACM_core_openMedicalMenu", _p] call CBA_fnc_localEvent;};}, [_patient]] call CBA_fnc_execNextFrame;
};
