// Physical front/back roll used by the chest-seal Flip button.
// This function owns ONLY the casualty. Provider theatre starts on the medic's client in fn_chestSealFlip.
params [["_patient", objNull, [objNull]], ["_target", "front", [""]], ["_force", false, [false]], ["_provider", objNull, [objNull]]];
if (isNull _patient || {!(_target in ["front", "back"])}) exitWith {};

if (!local _patient) exitWith {
    [_patient, "chestSealRoll", [_patient, _target, _force, _provider]] call ACME_fnc_ownerDispatch;
};

// Outside this minigame a body roll must tear down head elevation normally. Inside it, Semi-Fowler is only
// suspended, so the front/back roll theatre must not destroy the logical posture we will restore on exit.
if !(_patient getVariable ["ACME_CS_ProcedureActive", false]) then {
    [_patient] call ACME_fnc_headElevYieldForRoll;
};

private _actual = [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide;
_patient setVariable ["ACME_CS_facing", _actual, true];
if (!_force && {_actual isEqualTo _target}) exitWith {};

// Never invent a different diagram side when the body itself cannot be animated.
if ((!alive _patient) || {(lifeState _patient) isEqualTo "DEAD"} || {!isNull objectParent _patient}) exitWith {};

private _isUncon = (_patient getVariable ["ACE_isUnconscious", false]) || {_patient getVariable ["ace_medical_unconscious", false]};
private _isObtunded = _patient getVariable ["ACME_obtunded", false];
private _isGrounded = _isUncon || _isObtunded || {(stance _patient) == "PRONE"}
    || {_patient getVariable ["ACM_core_Lying_State", false]}
    || {_patient getVariable ["ACME_CS_ProcedureGrounded", false]};
if (!_isGrounded) exitWith {};

private _trans = if (_target isEqualTo "back") then {
    // posterior up -> patient rolls onto the front
    "AinjPpneMstpSnonWrflDnon_rolltofront"
} else {
    // anterior up -> patient rolls onto the back
    "AinjPpneMstpSnonWrflDnon_rolltoback"
};
private _hold = if (_target isEqualTo "back") then {
    missionNamespace getVariable ["ACME_uncon_faceDown", "ace_medical_engine_uncon_anim_1"]
} else {
    missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"]
};

// Ask for the smooth priority-1 transition first. ACM_LyingState is intentionally isolated and can swallow
// playMoveNow, so verify the requested roll actually began. If it did not, use ACE priority 2 once as a narrowly
// scoped state-graph repair. The token prevents an old fallback from overriding a newer flip.
private _token = format ["%1:%2:%3", clientOwner, CBA_missionTime, random 1];
private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
if (!(_rollTime isEqualType 0) || {_rollTime <= 0}) then {_rollTime = 1.85;};
private _leaseToken = [_patient, _trans, 1, "chest-seal-roll", _provider, _rollTime + 0.45, 3, _token] call ACME_fnc_patientAnimRequest;
if (_leaseToken == "") exitWith {_patient setVariable ["ACME_CS_rollUntil", -1, false];};
_patient setVariable ["ACME_CS_rollToken", _token, false];
_patient setVariable ["ACME_CS_rollUntil", CBA_missionTime + _rollTime, false];
[{
    params ["_p", "_tok", "_trans"];
    if (isNull _p || {!local _p} || {!alive _p} || {!isNull objectParent _p}) exitWith {};
    if ((_p getVariable ["ACME_CS_rollToken", ""]) != _tok) exitWith {};
    if ((toLower animationState _p) != (toLower _trans)) then {
        [_p, _trans, 2] call ACME_fnc_doAnim;
    };
}, [_patient, _token, _trans], 0.15] call CBA_fnc_waitAndExecute;

[{
    params ["_p", "_tok", "_hold", "_needsHold", "_target"];
    if (isNull _p || {!local _p}) exitWith {};
    if ((_p getVariable ["ACME_CS_rollToken", ""]) != _tok) exitWith {};
    _p setVariable ["ACME_CS_rollToken", "", false];
    _p setVariable ["ACME_CS_rollUntil", -1, false];
    if (!alive _p || {!isNull objectParent _p}) exitWith {};
    private _stillGrounded = (_p getVariable ["ACE_isUnconscious", false])
        || {_p getVariable ["ace_medical_unconscious", false]}
        || {_p getVariable ["ACME_obtunded", false]}
        || {(stance _p) == "PRONE"}
        || {_p getVariable ["ACM_core_Lying_State", false]}
        || {_p getVariable ["ACME_CS_ProcedureGrounded", false]};
    if (_needsHold && {_stillGrounded}) then {["ace_common_switchMove", [_p, _hold]] call CBA_fnc_globalEvent;};
    // Update the cache only after the physical endpoint is reached. UI classification still uses actual body
    // geometry/ACE animation first, so an external roll can immediately supersede this value.
    _p setVariable ["ACME_CS_facing", _target, true];
    // The carrier is parked once when chest access begins.  Keep that world-space placement through
    // front/back flips instead of shuttling the vest around the casualty on every roll.
}, [_patient, _token, _hold, _isGrounded, _target], _rollTime] call CBA_fnc_waitAndExecute;
