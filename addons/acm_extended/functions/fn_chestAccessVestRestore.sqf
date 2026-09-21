// Restore a temporarily removed chest plate carrier.
//
// Visible reverse choreography:
//   provider medic4 body-handling > patient Grab/Hold > real carrier restored while lifted > patient Release supine.
// Forced cleanup, dead/vehicle patients, or unsafe body-control cases restore gear immediately.
params [
    ["_patient", objNull, [objNull]],
    ["_force", false, [false]],
    ["_medic", objNull, [objNull]],
    ["_context", "access", [""]]
];
if (isNull _patient || {!local _patient}) exitWith {false};
_context = toLowerANSI _context;
if !(_context in ["access","chestseal"]) then {_context = "access";};

private _savedVar = ["ACME_chestAccess_vestLoadout","ACME_CS_vestLoadout"] select (_context == "chestseal");
private _propVar = ["ACME_chestAccess_vestProp","ACME_CS_vestProp"] select (_context == "chestseal");
private _busyVar = ["ACME_chestAccess_vestBusy","ACME_CS_vestBusy"] select (_context == "chestseal");
private _readyVar = ["ACME_chestAccess_readyServer","ACME_CS_vestReadyServer"] select (_context == "chestseal");
private _pfhVar = ["ACME_chestAccess_vestPFH","ACME_CS_vestPFH"] select (_context == "chestseal");

if (!_force) then {
    if (_context == "access") then {
        private _leases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
        if ((count _leases) > 0
            || {_patient getVariable ["ACME_CS_ProcedureActive", false]}
            || {_patient getVariable ["ACME_Thora_ChestAccessActive", false]}) exitWith {false};
    } else {
        if !((_patient getVariable ["ACME_CS_ProcedureTokens", []]) isEqualTo []) exitWith {false};
    };
};

private _saved = +(_patient getVariable [_savedVar, []]);
private _prop = _patient getVariable [_propVar, objNull];

private _finishBookkeeping = {
    params ["_p","_savedVar","_propVar","_busyVar","_readyVar","_pfhVar"];
    private _pfh = _p getVariable [_pfhVar,-1];
    if (_pfh isEqualType 0 && {_pfh >= 0}) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
    _p setVariable [_pfhVar,-1,false];
    _p setVariable [_propVar,objNull,true];
    _p setVariable [_savedVar,[],true];
    _p setVariable [_busyVar,"",false];
    _p setVariable [_readyVar,serverTime,true];

    // The Semi-Fowler support prop can now leave its chest-workspace park point and resume its normal placement.
    private _headProp = _p getVariable ["ACME_headElev_propObj", objNull];
    if (!isNull _headProp) then {_headProp setVariable ["ACME_chestFixedPark", nil, false];};
};

private _restoreNow = {
    params ["_p","_saved","_prop","_savedVar","_propVar","_busyVar","_readyVar","_pfhVar","_finish"];
    private _restored = true;
    if ((vest _p) == "") then {
        private _vestClass = _saved param [0,"",[""]];
        if (_vestClass != "") then {
            private _loadout = getUnitLoadout _p;
            if ((count _loadout) > 4) then {
                _loadout set [4,+_saved];
                _p setUnitLoadout [_loadout,false];
                _restored = (vest _p) == _vestClass;
            };
        };
    };
    if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
    [_p,_savedVar,_propVar,_busyVar,_readyVar,_pfhVar] call _finish;
    _restored
};

// Nothing is in custody.
if ((count _saved) != 2) exitWith {
    if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
    [_patient,_savedVar,_propVar,_busyVar,_readyVar,_pfhVar] call _finishBookkeeping;
    true
};

// Never run two reverse lifts for one custody record.
private _busy = _patient getVariable [_busyVar, ""];
if (_busy != "") exitWith {(_busy find "restore:") == 0};

// Animate only a stable, legitimately controllable, face-up casualty.
private _actualSide = [_patient, _patient getVariable ["ACME_CS_facing","front"]] call ACME_fnc_chestSealActualSide;
private _canAnimate = !_force
    && {alive _patient}
    && {isNull objectParent _patient}
    && {!([_patient] call ACME_fnc_animBlocked)}
    && {[_patient] call ACME_fnc_chestSealCanPhysicalRoll}
    && {_actualSide == "front"};

if (!_canAnimate) exitWith {
    [_patient,_saved,_prop,_savedVar,_propVar,_busyVar,_readyVar,_pfhVar,_finishBookkeeping] call _restoreNow
};

if (_context == "chestseal") then {[_patient] call ACME_fnc_chestSealParkCarrier}
else {[_patient] call ACME_fnc_chestAccessVestPark};

private _liftTime = missionNamespace getVariable ["ACME_headElev_liftAnimTime", 1.2];
if (!(_liftTime isEqualType 0) || {_liftTime <= 0}) then {_liftTime = 1.2;};
private _lowerTime = missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4];
if (!(_lowerTime isEqualType 0) || {_lowerTime <= 0}) then {_lowerTime = 1.4;};
private _holdTime = missionNamespace getVariable ["ACME_chestAccess_vestLiftHold", 0.18];
if (!(_holdTime isEqualType 0) || {_holdTime < 0}) then {_holdTime = 0.18;};
private _total = _liftTime + _holdTime + _lowerTime + 0.08;

private _serial = (_patient getVariable ["ACME_chestAccess_restoreSerial",0]) + 1;
_patient setVariable ["ACME_chestAccess_restoreSerial",_serial,false];
private _token = format ["restore:%1:%2:%3",_context,netId _patient,_serial];
_patient setVariable [_busyVar,_token,false];
_patient setVariable [_readyVar,serverTime + _total,true];

if (!isNull _medic && {!(_medic isEqualTo _patient)}) then {
    [_medic, "chestAccessVestProvider", [_medic, _patient, "start", false]] call ACME_fnc_ownerDispatch;
};

[_patient,false] call ACME_fnc_headElevCollision;
[_patient,"ACME_HeadElevPatientGrab",2,"chest-access-vest-restore",_medic,_total + 0.5,4,_token] call ACME_fnc_patientAnimRequest;
[_patient,_liftTime + _holdTime + 0.25] call ACME_fnc_headElevPinPose;

// Carrier returns only while the patient is lifted.
[{
    params ["_p","_ctx","_saved","_propVar","_busyVar","_token","_lowerTime","_medic"];
    if (isNull _p || {!local _p} || {(_p getVariable [_busyVar,""]) != _token}) exitWith {};

    if (_ctx == "chestseal") then {[_p] call ACME_fnc_chestSealParkCarrier}
    else {[_p] call ACME_fnc_chestAccessVestPark};

    if ((vest _p) == "") then {
        private _vestClass = _saved param [0,"",[""]];
        if (_vestClass != "") then {
            private _loadout = getUnitLoadout _p;
            if ((count _loadout) > 4) then {
                _loadout set [4,+_saved];
                _p setUnitLoadout [_loadout,false];
            };
        };
    };

    private _prop = _p getVariable [_propVar,objNull];
    if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
    _p setVariable [_propVar,objNull,true];

    if (alive _p && {isNull objectParent _p}) then {
        [_p,"ACME_HeadElevPatientRelease",2,"chest-access-vest-restore",_medic,_lowerTime + 0.4,4,_token] call ACME_fnc_patientAnimRequest;
        [_p,_lowerTime + 0.2] call ACME_fnc_headElevPinPose;
    };
}, [_patient,_context,_saved,_propVar,_busyVar,_token,_lowerTime,_medic], _liftTime + _holdTime] call CBA_fnc_waitAndExecute;

// Finish only after the patient is back down, then let the provider blend back to normal crouch.
[{
    params ["_p","_medic","_savedVar","_propVar","_busyVar","_readyVar","_pfhVar","_token","_finish"];
    if (isNull _p || {!local _p} || {(_p getVariable [_busyVar,""]) != _token}) exitWith {};

    [_p,true] call ACME_fnc_headElevCollision;

    private _lock = _p getVariable ["ACME_patientAnimLock",[]];
    if ((_lock param [0,""]) == _token && {(_lock param [1,""]) == "chest-access-vest-restore"}) then {
        _p setVariable ["ACME_patientAnimLock",[],true];
    };

    if (alive _p && {isNull objectParent _p} && {[_p] call ACME_fnc_chestSealCanPhysicalRoll}) then {
        private _faceUp = missionNamespace getVariable ["ACME_uncon_faceUp","ACM_LyingState"];
        if ((toLowerANSI animationState _p) != (toLowerANSI _faceUp)) then {
            ["ace_common_switchMove",[_p,_faceUp]] call CBA_fnc_globalEvent;
        };
        _p setVariable ["ACME_CS_facing","front",true];
    };

    [_p,_savedVar,_propVar,_busyVar,_readyVar,_pfhVar] call _finish;

    if (!isNull _medic && {!(_medic isEqualTo _p)}) then {
        [_medic, "chestAccessVestProvider", [_medic, _p, "stop", false]] call ACME_fnc_ownerDispatch;
    };
}, [_patient,_medic,_savedVar,_propVar,_busyVar,_readyVar,_pfhVar,_token,_finishBookkeeping], _total] call CBA_fnc_waitAndExecute;

true
