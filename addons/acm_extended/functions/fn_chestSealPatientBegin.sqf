// Begin the temporary casualty workspace used by the chest-seal minigame.
// The first viewer owns physical preparation; later viewers join the already prepared state.
params [
    ["_patient", objNull, [objNull]],
    ["_token", "", [""]],
    ["_medic", objNull, [objNull]]
];
if (isNull _patient || {_token == ""}) exitWith {};
if (!local _patient) exitWith {
    [_patient, "chestSealPatientBegin", [_patient, _token, _medic]] call ACME_fnc_ownerDispatch;
};

private _tokens = +(_patient getVariable ["ACME_CS_ProcedureTokens", []]);
if (_token in _tokens) exitWith {};
private _first = !(_patient getVariable ["ACME_CS_ProcedureActive", false]);
_patient setVariable ["ACME_CS_ProcedureGeneration", 1 + (_patient getVariable ["ACME_CS_ProcedureGeneration", 0])];
_tokens pushBack _token;
_patient setVariable ["ACME_CS_ProcedureTokens", _tokens, true];
_patient setVariable ["ACME_CS_ProcedureActive", true, true];

// Additional viewers share the existing preparation/ready timestamp.
if (!_first) exitWith {};

private _preHeadElev = _patient getVariable ["ACME_headElevated", false];
private _preSide = if (_preHeadElev) then {
    "front"
} else {
    [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide
};
private _preRecovery = _patient getVariable ["ACM_airway_RecoveryPosition_State", false];
private _preLying = _patient getVariable ["ACM_core_Lying_State", false];
private _preAnim = animationState _patient;
private _preGrounded = [_patient] call ACME_fnc_chestSealCanPhysicalRoll;

_patient setVariable ["ACME_CS_PreProcedureState", [_preSide, _preHeadElev, _preRecovery, _preLying, _preAnim], true];
_patient setVariable ["ACME_CS_ProcedureGrounded", _preGrounded, true];
_patient setVariable ["ACME_CS_facing", _preSide, true];
_patient setVariable ["ACME_CS_rollUntil", -1, false];
_patient setVariable ["ACME_CS_ProcedureReadyAt", -1, true];

// Recovery position is suspended for the workspace; exact restoration happens after carrier restoration on close.
if (_preRecovery) then {
    _patient setVariable ["ACM_airway_RecoveryPosition_State", false, true];
    _patient setVariable ["ACM_airway_HeadTilt_State", false, true];
};

// New workspace custody starts with clean carrier bookkeeping.
private _staleSaved = +(_patient getVariable ["ACME_CS_vestLoadout", []]);
if ((count _staleSaved) == 2) then {
    // A previous interrupted workspace left gear in custody. Restore correctness first, then begin this episode.
    [_patient, true, _medic, "chestseal"] call ACME_fnc_chestAccessVestRestore;
};
_patient setVariable ["ACME_CS_vestReadyServer", -1, true];

// Animated carrier preparation owns Semi-Fowler lowering, lift/remove/park/lower, and fixed world-space parking.
[_patient, _medic, "chestseal"] call ACME_fnc_chestAccessVestAcquire;

// Only after the carrier transaction is done may the workspace normalize a legitimately controllable casualty
// to the anterior side. Carrier removal itself normally already leaves the casualty supine.
[{
    params ["_p"];
    private _ready = _p getVariable ["ACME_CS_vestReadyServer", -1];
    (_ready isEqualType 0) && {_ready >= 0} && {serverTime >= _ready}
}, {
    params ["_p","_preSide","_preGrounded"];

    if (isNull _p || {!local _p} || {!(_p getVariable ["ACME_CS_ProcedureActive", false])}) exitWith {};

    private _canNormalize = alive _p && {isNull objectParent _p} && {_preGrounded};
    private _actual = [_p, _p getVariable ["ACME_CS_facing", _preSide]] call ACME_fnc_chestSealActualSide;

    if (_canNormalize && {_actual != "front"}) then {
        [_p, "front", false, objNull] call ACME_fnc_chestSealRoll;
        private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
        if (!(_rollTime isEqualType 0) || {_rollTime < 0}) then {_rollTime = 1.85;};
        _p setVariable ["ACME_CS_ProcedureReadyAt", serverTime + _rollTime + 0.08, true];
    } else {
        _p setVariable ["ACME_CS_facing", "front", true];
        _p setVariable ["ACME_CS_ProcedureReadyAt", serverTime, true];
    };
}, [_patient,_preSide,_preGrounded], 10, {
    params ["_p"];
    if (!isNull _p && {local _p}) then {
        // Fail closed for the workspace. The caller's 12 s timeout will close cleanly rather than opening over
        // an unfinished patient animation.
        _p setVariable ["ACME_CS_ProcedureReadyAt", -1, true];
    };
}] call CBA_fnc_waitUntilAndExecute;
