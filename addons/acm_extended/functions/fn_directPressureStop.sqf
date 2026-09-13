// Idempotent direct-pressure teardown for an explicit medic. It is safe after distance break, death, menu stop,
// respawn, a stale PFH, a movement escape, or a partially-started hold. The old function hard-coded ACE_player
// and returned immediately when ACME_DP_Active was already false, leaving stale patient markers/key handlers that
// prevented the next hold.
params [["_silent", false, [false]], ["_medic", ACE_player, [objNull]]];
if (isNull _medic) exitWith {};

private _wasActive = _medic getVariable ["ACME_DP_Active", false];
private _patient = _medic getVariable ["ACME_DP_Patient", objNull];
private _part = _medic getVariable ["ACME_DP_Part", ""];
private _mode = _medic getVariable ["ACME_DP_Mode", ""];
private _wasInPose = _medic getVariable ["ACME_DP_InPose", false];
private _stateBefore = toLower animationState _medic;

// Retire every delayed direct-pressure pose request first. ACME_DP_PoseToken belongs to the DP layer itself;
// ACME_dah_gen owns ACME_fnc_doAnimHeld's short reassert worker. Failing to invalidate the latter allowed the
// pressure hold to come back after a tourniquet or another treatment had already taken the provider animation.
_medic setVariable ["ACME_DP_PoseToken", (_medic getVariable ["ACME_DP_PoseToken", 0]) + 1];
_medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];

private _pfh = _medic getVariable ["ACME_DP_PFH", -1];
if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
{[_x, "keydown"] call CBA_fnc_removeKeyHandler;} forEach (_medic getVariable ["ACME_DP_KeyIDs", []]);
private _d3 = _medic getVariable ["ACME_DP_Draw3D", -1];
if (_d3 >= 0) then {removeMissionEventHandler ["Draw3D", _d3];};
[] call ace_interaction_fnc_hideMouseHint;

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

// Release only our decorative hold. Never clear another ACM continuous action. First request the normal authored
// transition. If the engine is still physically in ACME_DirectPressureHold on the next beat, use priority 2 as a
// narrowly-scoped repair. That fallback is what guarantees a movement key can never leave the provider welded in
// the pressure pose, without making ordinary treatment animation exits snap.
private _ownsHold = _wasInPose || {_mode == "torso"} || {_stateBefore == "acme_directpressurehold"};
if (local _medic && {alive _medic} && {isNull objectParent _medic} && {_ownsHold}) then {
    _medic setUnitPos "AUTO";
    [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;
    [{
        params ["_m"];
        if (isNull _m || {!local _m} || {!alive _m} || {!isNull objectParent _m}) exitWith {};
        if ((toLower animationState _m) != "acme_directpressurehold") exitWith {};
        _m setUnitPos "AUTO";
        [_m, "AmovPknlMstpSnonWnonDnon", 2] call ACME_fnc_doAnim;
    }, [_medic], 0.08] call CBA_fnc_waitAndExecute;
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
    ["ACME_DP_LastPoseAssert", 0]
];

if (_wasActive) then {
    if (!_silent) then {["Released direct pressure.", 1.5, _medic] call ace_common_fnc_displayTextStructured;};
    if (!isNull _patient) then {
        [_patient, "activity", "%1 stopped Direct pressure on %2", "%1 stopped Direct pressure on %2",
            [[_medic, false, true] call ace_common_fnc_getName, ([_part, "abbr"] call ACME_fnc_bodyPartName)]] call ACME_fnc_medLog;
    };
};
