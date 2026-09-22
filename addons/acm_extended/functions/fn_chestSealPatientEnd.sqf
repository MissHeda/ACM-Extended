// End the chest-seal casualty workspace.
// Final viewer teardown is deliberately ordered:
//   cancel/finish live roll > normalize front > lift and restore carrier > lay supine.
// Chest work NEVER restores a posterior/prone or recovery-position body pose on exit.
params [
    ["_patient", objNull, [objNull]],
    ["_token", "", [""]],
    ["_medic", objNull, [objNull]]
];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    [_patient, "chestSealPatientEnd", [_patient, _token, _medic]] call ACME_fnc_ownerDispatch;
};

private _tokens = +(_patient getVariable ["ACME_CS_ProcedureTokens", []]);
if (_token == "" || {!(_token in _tokens)}) exitWith {};
_tokens = _tokens - [_token];
private _generation = _patient getVariable ["ACME_CS_ProcedureGeneration", 0];
_patient setVariable ["ACME_CS_ProcedureTokens", _tokens, true];
if !(_tokens isEqualTo []) exitWith {};
if !(_patient getVariable ["ACME_CS_ProcedureActive", false]) exitWith {};

private _pre = +(_patient getVariable ["ACME_CS_PreProcedureState", ["front", false, false, false, ""]]);
private _preSide = _pre param [0, "front", [""]];
private _preHeadElev = _pre param [1, false, [false]];
private _preRecovery = _pre param [2, false, [false]];
private _preAnim = _pre param [4, "", [""]];
if !(_preSide in ["front","back"]) then {_preSide = "front";};
if (_preHeadElev) then {_preSide = "front";};

private _finalize = {
    params ["_p","_wasHeadElev","_generation"];
    if (isNull _p || {!local _p}
        || {(_p getVariable ["ACME_CS_ProcedureGeneration",-1]) != _generation}
        || {!((_p getVariable ["ACME_CS_ProcedureTokens",[]]) isEqualTo [])}) exitWith {};

    _p setVariable ["ACME_CS_ProcedureActive", false, true];
    _p setVariable ["ACME_CS_ProcedureReadyAt", -1, true];
    _p setVariable ["ACME_CS_ProcedureGrounded", false, true];
    _p setVariable ["ACME_CS_PreProcedureState", [], true];
    _p setVariable ["ACME_CS_rollUntil", -1, false];
    _p setVariable ["ACME_CS_rollToken", "", false];
    _p setVariable ["ACME_CS_vestReadyServer", -1, true];
    _p setVariable ["ACME_CS_facing", "front", true];

    private _headProp = _p getVariable ["ACME_headElev_propObj", objNull];
    if (!isNull _headProp) then {_headProp setVariable ["ACME_chestFixedPark", nil, false];};

    // The casualty leaves chest work anterior-up. If a controllable grounded patient drifted to a posterior
    // animation during teardown, force the stable face-up rest before any Semi-Fowler resume.
    if (alive _p && {isNull objectParent _p} && {[_p] call ACME_fnc_chestSealCanPhysicalRoll}) then {
        private _faceUp = missionNamespace getVariable ["ACME_uncon_faceUp","ACM_LyingState"];
        if ((toLowerANSI animationState _p) != (toLowerANSI _faceUp)) then {
            ["ace_common_switchMove",[_p,_faceUp]] call CBA_fnc_globalEvent;
        };
    };

    if (_wasHeadElev
        && {_p getVariable ["ACME_headElevated", false]}
        && {_p getVariable ["ACME_headElev_Suspended", false]}
        && {((_p getVariable ["ACME_lido_seizureState",""]) in ["","postictal"])}) then {
        _p setVariable ["ACME_headElev_ResumePending", true, true];
        [{_this call ACME_fnc_headElevTryResume;}, [_p], 0.25] call CBA_fnc_waitAndExecute;
    };
};

private _restoreCarrier = {
    params ["_p","_medic","_head","_generation","_finalize","_restoreCarrier"];
    if (isNull _p || {!local _p}
        || {(_p getVariable ["ACME_CS_ProcedureGeneration",-1]) != _generation}) exitWith {};

    private _busy = _p getVariable ["ACME_CS_vestBusy",""];
    if (_busy != "" && {(_busy find "restore:") != 0}) exitWith {
        // Closing during preparation: let the in-flight removal finish, then reverse it cleanly.
        [{
            params ["_p"];
            (_p getVariable ["ACME_CS_vestBusy",""]) == ""
        }, {
            _this call (_this select 9);
        }, [_p,_medic,_head,_generation,_finalize,_restoreCarrier], 12, {
            params ["_p","_medic","_head","_generation","_finalize"];
            [_p,_head,_generation] call _finalize;
        }] call CBA_fnc_waitUntilAndExecute;
    };

    private _saved = +(_p getVariable ["ACME_CS_vestLoadout", []]);
    if ((count _saved) != 2) exitWith {
        [_p,_head,_generation] call _finalize;
    };

    private _started = [_p,false,_medic,"chestseal"] call ACME_fnc_chestAccessVestRestore;
    if (!_started) exitWith {
        [_p,_head,_generation] call _finalize;
    };

    [{
        params ["_p"];
        (_p getVariable ["ACME_CS_vestBusy",""]) == ""
            && {(count (_p getVariable ["ACME_CS_vestLoadout",[]])) != 2}
    }, {
        params ["_p","_head","_generation","_finalize"];
        [_p,_head,_generation] call _finalize;
    }, [_p,_head,_generation,_finalize], 12, {
        params ["_p","_head","_generation","_finalize"];
        // Gear function has its own fail-safe paths. Never strand procedure state if presentation stalls.
        [_p,_head,_generation] call _finalize;
    }] call CBA_fnc_waitUntilAndExecute;
};

// Carrier restoration is authored from face-up and chest work always exits face-up.
private _beginRestore = {
    params ["_p","_medic","_head","_generation","_restoreCarrier","_finalize"];
    if (isNull _p || {!local _p}) exitWith {};

    private _actual = [_p, _p getVariable ["ACME_CS_facing","front"]] call ACME_fnc_chestSealActualSide;
    private _canRoll = alive _p && {isNull objectParent _p} && {[_p] call ACME_fnc_chestSealCanPhysicalRoll};

    if (_canRoll && {_actual != "front"}) then {
        [_p, "front", false, objNull] call ACME_fnc_chestSealRoll;
        private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime",1.85];
        if !(_rollTime isEqualType 0 && {finite _rollTime}) then {_rollTime = 1.85;};
        [{
            params ["_p","_medic","_head","_generation","_restoreCarrier","_finalize"];
            [_p,_medic,_head,_generation,_finalize,_restoreCarrier] call _restoreCarrier;
        }, [_p,_medic,_head,_generation,_restoreCarrier,_finalize], (_rollTime max 0.1) + 0.08] call CBA_fnc_waitAndExecute;
    } else {
        _p setVariable ["ACME_CS_facing","front",true];
        [_p,_medic,_head,_generation,_finalize,_restoreCarrier] call _restoreCarrier;
    };
};

// Closing during a live Flip is an explicit abort. Stop the current patient roll now and settle front for the
// carrier reverse sequence rather than letting the old roll finish underneath restoration.
private _rollToken = _patient getVariable ["ACME_CS_rollToken",""];
private _rollUntil = _patient getVariable ["ACME_CS_rollUntil",-1];
private _rollActive = (_rollToken != "") || {(_rollUntil isEqualType 0) && {_rollUntil > CBA_missionTime}};
if (_rollActive) then {
    [_patient, "front"] call ACME_fnc_patientRollCancel;
};

[_patient,_medic,_preHeadElev,_generation,_restoreCarrier,_finalize] call _beginRestore;
