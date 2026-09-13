// Temporarily lay an elevated casualty flat for a treatment.
// The authored release always runs first. Ordinary treatments may restore a carrier to the chest while flat;
// auscultation explicitly keeps the carrier out of the way for the entire scope session, matching the CPR-style
// chest-access posture. The casualty is never given a new logical ACM lying-state flag here.
params [["_patient", objNull, [objNull]], ["_keepVestOut", false, [false]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevSuspend", [_patient, _keepVestOut]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !((_patient getVariable ["ACME_headElev_hold", []]) isEqualTo []) exitWith {[objNull, _patient] call ACME_fnc_headElevateStop;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};

// Small local helper: park the visual carrier/support just beyond the head so the chest remains unobstructed.
private _parkProp = {
    params ["_p"];
    private _prop = _p getVariable ["ACME_headElev_propObj", objNull];
    if (isNull _prop) exitWith {};
    detach _prop;
    private _pel = _p modelToWorldVisual (_p selectionPosition "pelvis");
    private _hed = _p modelToWorldVisual (_p selectionPosition "head");
    private _dx = (_hed select 0) - (_pel select 0);
    private _dy = (_hed select 1) - (_pel select 1);
    private _mag = sqrt ((_dx * _dx) + (_dy * _dy));
    if (_mag < 0.05) then {private _dir = getDir _p; _dx = sin _dir; _dy = cos _dir; _mag = 1;};
    private _axis = [_dx / _mag, _dy / _mag, 0];
    private _gap = missionNamespace getVariable ["ACME_headElev_propGroundGap", 0.45];
    private _px = (_hed select 0) + ((_axis select 0) * _gap);
    private _py = (_hed select 1) + ((_axis select 1) * _gap);
    _prop setPosATL [_px, _py, 0.02];
    _prop setVectorDirAndUp [_axis, surfaceNormal [_px, _py]];
};

if (_keepVestOut) then {_patient setVariable ["ACME_headElev_suspendKeepVestOut", true, true];};

// A second provider can join while the patient is already flat. If that provider needs an unobstructed chest,
// upgrade the existing suspension rather than replaying the lowering animation.
if (_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {
    if (_keepVestOut) then {
        private _suspendVest = +(_patient getVariable ["ACME_headElev_suspendVestLoadout", []]);
        if ((count _suspendVest) == 2) then {
            private _vestClass = _suspendVest param [0, "", [""]];
            if (_vestClass != "" && {(vest _patient) == _vestClass}) then {
                private _items = vestItems _patient;
                removeVest _patient;
                if ((vest _patient) == "") then {
                    _patient setVariable ["ACME_headElev_vestLoadout", +_suspendVest, true];
                    _patient setVariable ["ACME_headElev_vestRemoved", true, true];
                    _patient setVariable ["ACME_headElev_propVest", _vestClass, true];
                    _patient setVariable ["ACME_headElev_propVestItems", _items, true];
                    private _model = getText (configFile >> "CfgWeapons" >> _vestClass >> "model");
                    private _prop = objNull;
                    if (_model != "") then {_prop = createSimpleObject [_model, [0,0,0], false];};
                    if (isNull _prop) then {
                        _prop = createVehicle ["GroundWeaponHolder", getPosATL _patient, [], 0, "CAN_COLLIDE"];
                        _prop addItemCargoGlobal [_vestClass, 1];
                    };
                    _patient setVariable ["ACME_headElev_propObj", _prop, true];
                };
            };
        };
        [_patient] call _parkProp;
    };
};

_patient setVariable ["ACME_headElev_Suspended", true, true];
_patient setVariable ["ACME_headElev_visualActive", false, true];

private _lowerTime = missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4];
if (!(_lowerTime isEqualType 0) || {_lowerTime < 0.2}) then {_lowerTime = 1.4;};
_patient setVariable ["ACME_headElev_suspendReadyAt", CBA_missionTime + _lowerTime, false];

private _suspendVest = [];
if (_patient getVariable ["ACME_headElev_vestRemoved", false]) then {_suspendVest = +(_patient getVariable ["ACME_headElev_vestLoadout", []]);};
_patient setVariable ["ACME_headElev_suspendVestLoadout", _suspendVest, false];

private _patientAnimToken = "";
if (isNull objectParent _patient) then {
    [_patient, false] call ACME_fnc_headElevCollision;
    _patientAnimToken = [_patient, "ACME_HeadElevPatientRelease", 2, "head-elev-lower", objNull, _lowerTime + 0.3, 3] call ACME_fnc_patientAnimRequest;
    [_patient, _lowerTime] call ACME_fnc_headElevPinPose;
};
private _poseToken = _patient getVariable ["ACME_headElev_poseToken", ""];
[{
    params ["_patient", "_poseToken", "_suspendVest", "_patientAnimToken"];
    if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
    [_patient, true] call ACME_fnc_headElevCollision;
    if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _poseToken
        || {!(_patient getVariable ["ACME_headElev_Suspended", false])}) exitWith {};

    private _keepOut = _patient getVariable ["ACME_headElev_suspendKeepVestOut", false];
    if ((count _suspendVest) == 2 && {!_keepOut}) then {
        private _restored = [_patient] call ACME_fnc_headElevVestRestore;
        if (_restored) then {
            private _prop = _patient getVariable ["ACME_headElev_propObj", objNull];
            if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
            _patient setVariable ["ACME_headElev_propObj", objNull, true];
            _patient setVariable ["ACME_headElev_suspendVestLoadout", +_suspendVest, false];
        };
    } else {
        private _prop = _patient getVariable ["ACME_headElev_propObj", objNull];
        if (!isNull _prop) then {
            detach _prop;
            private _pel = _patient modelToWorldVisual (_patient selectionPosition "pelvis");
            private _hed = _patient modelToWorldVisual (_patient selectionPosition "head");
            private _dx = (_hed select 0) - (_pel select 0); private _dy = (_hed select 1) - (_pel select 1);
            private _mag = sqrt ((_dx*_dx)+(_dy*_dy));
            if (_mag < 0.05) then {private _dir=getDir _patient; _dx=sin _dir; _dy=cos _dir; _mag=1;};
            private _axis=[_dx/_mag,_dy/_mag,0]; private _gap=missionNamespace getVariable ["ACME_headElev_propGroundGap",0.45];
            private _px=(_hed select 0)+((_axis select 0)*_gap); private _py=(_hed select 1)+((_axis select 1)*_gap);
            _prop setPosATL [_px,_py,0.02]; _prop setVectorDirAndUp [_axis,surfaceNormal [_px,_py]];
        };
    };

    private _rest = [_patient] call ACME_fnc_headElevRestAnim;
    if (isNull objectParent _patient && {_rest != ""} && {_patientAnimToken != ""}) then {
        // Continue the same owner-side lowering transaction. Reusing the token is important: an equal-priority
        // lock from the release must not reject its own final face-up rest on the next animation step.
        [_patient, _rest, 2, "head-elev-flat", objNull, 0.8, 3, _patientAnimToken] call ACME_fnc_patientAnimRequest;
    };
}, [_patient,_poseToken,_suspendVest,_patientAnimToken], _lowerTime] call CBA_fnc_waitAndExecute;
