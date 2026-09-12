// limb and head direct pressure: the free-movement holding pose. it is called every limb tick.
// the medic can move around freely, and if they go idle, meaning no move input and no displacement, for about 0.8 s
// while looking toward the patient, they adopt the connected direct-pressure hold, the same as the torso. it does not
// lock them: any move input or looking away drops the pose so they move normally.
// the pose enters/exits through ACE doAnimation priority 1 and a connected CfgMoves state, so the engine blends it. the looking test is
// horizontal facing and pitch-independent, so looking down at a downed patient and looking level both count.
params ["_medic", "_patient"];
private _inPose = _medic getVariable ["ACME_DP_InPose", false];

// Medical-menu/treatment ownership always wins over the decorative hold pose. This prevents the 0.15 s pressure
// tick from immediately overwriting another intervention's provider animation.
private _treating = dialog
    || {_medic getVariable ["ACME_treatmentPreflightActive", false]}
    || {(_medic getVariable ["ace_medical_treatment_endInAnim", ""]) != ""}
    || {missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]};
if (_treating) exitWith {
    if (_inPose && {!([_medic] call ACME_fnc_animBlocked)}) then {
        [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;
    };
    _medic setVariable ["ACME_DP_InPose", false];
    _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
};

// there is no pose in a vehicle.
if (!isNull objectParent _medic) exitWith {
    if (_inPose) then {
        if !([_medic] call ACME_fnc_animBlocked) then { [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim; };
        _medic setVariable ["ACME_DP_InPose", false];
    };
};

private _now = CBA_missionTime;

// the movement intent: the movement keys or actual displacement since the last tick.
private _moveInput = (inputAction "MoveForward") + (inputAction "MoveBack")
                   + (inputAction "MoveLeft") + (inputAction "MoveRight")
                   + (inputAction "MoveFastForward") + (inputAction "MoveSlowForward")
                   + (inputAction "Evasive");
private _lastPos = _medic getVariable ["ACME_DP_LastPos", getPosASL _medic];
private _cur = getPosASL _medic;
_medic setVariable ["ACME_DP_LastPos", _cur];
private _moving = (_moveInput > 0) || {(_cur distance _lastPos) > 0.04};

// looking toward the patient, on horizontal facing, pitch-independent.
private _dv = (getPosVisual _patient) vectorDiff (getPosVisual _medic);
private _dv2 = [_dv select 0, _dv select 1, 0];
private _lk = eyeDirection _medic;
private _lk2 = [_lk select 0, _lk select 1, 0];
private _looking = if (_dv2 isEqualTo [0,0,0] || {_lk2 isEqualTo [0,0,0]}) then { true } else {
    ((vectorNormalized _dv2) vectorDotProduct (vectorNormalized _lk2)) > (missionNamespace getVariable ["ACME_DP_lookDot", 0.4])
};

if (_moving || {!_looking}) then {
    if (_inPose) then {
        // Leave through the CfgMoves interpolation into a movable crouch. Player movement can
        // immediately supersede this playMoveNow; there is no frozen switchMove state to clear.
        [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;
        _medic setVariable ["ACME_DP_InPose", false];
    };
    _medic setVariable ["ACME_DP_IdleStart", _now];
} else {
    if (!_inPose) then {
        private _idleStart = _medic getVariable ["ACME_DP_IdleStart", _now];
        if ((_now - _idleStart) >= (missionNamespace getVariable ["ACME_DP_idleToPose", 0.8])) then {
            // Do not re-holster here. The action already performed its one weapon-clear at entry.
            [_medic, "ACME_DirectPressureHold", 1] call ACME_fnc_doAnim;
            _medic setVariable ["ACME_DP_InPose", true];
        };
    };
};
