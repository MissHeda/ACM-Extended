// B70 temporarily lay an elevated casualty flat for torso procedures without a helper attachment or teleport.
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevSuspend", [_patient]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !((_patient getVariable ["ACME_headElev_hold", []]) isEqualTo []) exitWith {[objNull, _patient] call ACME_fnc_headElevateStop;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};
if (_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {};
_patient setVariable ["ACME_headElev_Suspended", true, true];
_patient setVariable ["ACME_headElev_visualActive", false, true];

if (isNull objectParent _patient) then {
    [_patient, false] call ACME_fnc_headElevCollision;
    [_patient, "ACME_HeadElevPatientRelease", 2] call ACME_fnc_doAnim;
    [_patient, missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4]] call ACME_fnc_headElevPinPose;
};
private _poseToken = _patient getVariable ["ACME_headElev_poseToken", ""];
[{ 
    params ["_patient", "_poseToken"];
    if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
    [_patient, true] call ACME_fnc_headElevCollision;
    if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _poseToken || {!(_patient getVariable ["ACME_headElev_Suspended", false])}) exitWith {};
    // The release has continued into the BI injured supine idle. Return the casualty to the pose it had before the
    // lift. Priority 2 is required: the BI idle has no edge into ACM_LyingState or an ACE unconscious pose.
    private _rest = [_patient] call ACME_fnc_headElevRestAnim;
    if (isNull objectParent _patient && {_rest != ""}) then {[_patient, _rest, 2] call ACME_fnc_doAnim;};
    // Ground the visual prop only; never setPos the casualty.
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
}, [_patient,_poseToken], missionNamespace getVariable ["ACME_headElev_lowerAnimTime",1.4]] call CBA_fnc_waitAndExecute;
