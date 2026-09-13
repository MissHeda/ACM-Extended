// Temporarily lay an elevated casualty flat for torso procedures without a helper attachment or teleport.
// The authored release animation always runs first. If head elevation used the casualty's plate carrier as the
// bolster, the carrier is then restored to the worn chest slot for the entire flat-treatment interval. Resume
// removes it again and recreates the visual bolster before replaying the lift.
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevSuspend", [_patient]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !((_patient getVariable ["ACME_headElev_hold", []]) isEqualTo []) exitWith {[objNull, _patient] call ACME_fnc_headElevateStop;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};
if (_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {};
_patient setVariable ["ACME_headElev_Suspended", true, true];
_patient setVariable ["ACME_headElev_visualActive", false, true];

private _lowerTime = missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4];
if (!(_lowerTime isEqualType 0) || {_lowerTime < 0.2}) then {_lowerTime = 1.4;};
_patient setVariable ["ACME_headElev_suspendReadyAt", CBA_missionTime + _lowerTime, false];

// Capture the exact loadout entry before headElevVestRestore clears the normal elevation custody record.
private _suspendVest = [];
if (_patient getVariable ["ACME_headElev_vestRemoved", false]) then {
    _suspendVest = +(_patient getVariable ["ACME_headElev_vestLoadout", []]);
};
_patient setVariable ["ACME_headElev_suspendVestLoadout", _suspendVest, false];

if (isNull objectParent _patient) then {
    [_patient, false] call ACME_fnc_headElevCollision;
    [_patient, "ACME_HeadElevPatientRelease", 2] call ACME_fnc_doAnim;
    [_patient, _lowerTime] call ACME_fnc_headElevPinPose;
};
private _poseToken = _patient getVariable ["ACME_headElev_poseToken", ""];
[{
    params ["_patient", "_poseToken", "_suspendVest"];
    if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
    [_patient, true] call ACME_fnc_headElevCollision;
    if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _poseToken
        || {!(_patient getVariable ["ACME_headElev_Suspended", false])}) exitWith {};

    if ((count _suspendVest) == 2) then {
        // A plate-carrier bolster belongs back on the casualty's chest while the head is flat. Remove the prop only
        // after the real vest has been restored, so there is no frame where the item is visually lost.
        private _restored = [_patient] call ACME_fnc_headElevVestRestore;
        if (_restored) then {
            private _prop = _patient getVariable ["ACME_headElev_propObj", objNull];
            if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
            _patient setVariable ["ACME_headElev_propObj", objNull, true];
            _patient setVariable ["ACME_headElev_suspendVestLoadout", +_suspendVest, false];
        };
    } else {
        // Backpack/manual support has no removed carrier. If a legacy prop exists, ground it while flat.
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

    // Apply the final flat/resting pose after gear restoration. setUnitLoadout can reset a unit's current animation,
    // so doing this last prevents the carrier return from undoing the completed head-lowering state.
    private _rest = [_patient] call ACME_fnc_headElevRestAnim;
    if (isNull objectParent _patient && {_rest != ""}) then {[_patient, _rest, 2] call ACME_fnc_doAnim;};
}, [_patient,_poseToken,_suspendVest], _lowerTime] call CBA_fnc_waitAndExecute;
