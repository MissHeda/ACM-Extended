// Patient-owner PhysX loop. addForce is an impulse for one frame, so every impulse is scaled by diag_deltaTime.
// This makes the drag spring frame-rate independent.
params ["_args","_handle"];
_args params ["_patient","_medic","_weight","_lastRagdoll",["_stuckSince",-1]];

private _stop = {
    params ["_reason"];
    [_patient,_medic,_reason] call ACME_fnc_dragHandleStopOwner;
};

if (isNull _patient || {isNull _medic}) exitWith {["lost"] call _stop;};
if (!local _patient) exitWith {
    // Do not leave a half-owned physics transaction after locality migration. The old owner retires its PFH and
    // asks the new owner to perform an ordinary teardown. A later interaction can immediately attach again.
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_patient,"dragHandleStop",[_patient,_medic,"locality"]] call ACME_fnc_ownerDispatch;
};
if !(_patient getVariable ["ACME_dragHandle_active",false]) exitWith {[_handle] call CBA_fnc_removePerFrameHandler;};
if (!alive _patient || {!alive _medic}) exitWith {["death"] call _stop;};
if (_medic getVariable ["ACE_isUnconscious",false]) exitWith {["dragger_unconscious"] call _stop;};
if (!(isNull (objectParent _patient)) || {!(isNull (objectParent _medic))}) exitWith {["vehicle"] call _stop;};
if ((_patient call ace_common_fnc_isBeingDragged) || {_patient call ace_common_fnc_isBeingCarried}) exitWith {["ace_transport"] call _stop;};
if (_medic getVariable ["ace_dragging_isDragging",false] || {_medic getVariable ["ace_dragging_isCarrying",false]}) exitWith {["ace_transport"] call _stop;};

private _handleModel = _patient selectionPosition "Spine3";
if !(_handleModel isEqualType [] && {count _handleModel >= 3} && {vectorMagnitude _handleModel > 0.05}) then {
    _handleModel = [0,0,0.78];
};
private _patientPos = _patient modelToWorldVisual _handleModel;
private _anchor = _medic modelToWorldVisual [0,-0.30,0.55];
private _delta = [
    (_anchor select 0) - (_patientPos select 0),
    (_anchor select 1) - (_patientPos select 1),
    (_anchor select 2) - (_patientPos select 2)
];
private _distance = vectorMagnitude _delta;
private _releaseDist = missionNamespace getVariable ["ACME_dragHandle_releaseDistance",2.65];
if (_distance > _releaseDist) exitWith {["overstretch"] call _stop;};

private _slack = missionNamespace getVariable ["ACME_dragHandle_slackLength",1.0];
private _stretch = (_distance - _slack) max 0;
private _tension = linearConversion [_slack,_releaseDist,_distance,0,1,true];
_patient setVariable ["ACME_dragHandle_tension",_tension];

if (_stretch > 0.01 && {_distance > 0.01}) then {
    // Limit vertical authority. The upper-torso attachment still helps the body climb steps, but cannot launch it.
    private _pull = +_delta;
    _pull set [2,((_pull select 2) max -0.35) min 0.48];
    private _pullLen = vectorMagnitude _pull;
    if (_pullLen > 0.01) then {
        private _dir = _pull vectorMultiply (1 / _pullLen);
        private _pv = velocity _patient;
        private _mv = velocity _medic;
        private _rel = [(_pv select 0)-(_mv select 0),(_pv select 1)-(_mv select 1),(_pv select 2)-(_mv select 2)];
        private _closing = _rel vectorDotProduct _dir;

        private _spring = missionNamespace getVariable ["ACME_dragHandle_springAccelPerM",8.0];
        private _damping = missionNamespace getVariable ["ACME_dragHandle_damping",2.1];
        private _maxAccel = missionNamespace getVariable ["ACME_dragHandle_maxAccel",5.2];
        private _weightScale = linearConversion [350,950,_weight,1,0.58,true];
        private _accel = (((_stretch * _spring) - (_closing * _damping)) max 0) min _maxAccel) * _weightScale;

        // addForce uses impulse units. Multiply desired acceleration by physical mass and frame time.
        private _dt = (diag_deltaTime max 0.006) min 0.05;
        private _physMass = (getMass _patient) max 55;
        private _impulse = _dir vectorMultiply (_physMass * _accel * _dt);
        _patient addForce [_impulse,_handleModel,false];
    };
};

// ACE eventually parks an unconscious casualty in a locked pose. If meaningful tether tension is present but the
// body remains nearly motionless while the medic is moving, wake a fresh ragdoll. The long cooldown prevents
// obstacle snags from becoming a repeated flop loop.
private _bodySpeed = vectorMagnitude (velocity _patient);
private _medicSpeed = vectorMagnitude (velocity _medic);
if (_tension > 0.24 && {_medicSpeed > 0.65} && {_bodySpeed < 0.12}) then {
    if (_stuckSince < 0) then {_stuckSince = CBA_missionTime; _args set [4,_stuckSince];};
    if ((CBA_missionTime - _stuckSince) > 0.45 && {(CBA_missionTime - _lastRagdoll) > 1.8}) then {
        [_patient] call ACME_fnc_forceRagdoll;
        _lastRagdoll = CBA_missionTime;
        _args set [3,_lastRagdoll];
        _args set [4,CBA_missionTime];
    };
} else {
    if (_stuckSince >= 0) then {_args set [4,-1];};
};
