disableSerialization;
private _d = findDisplay 87200;
if (isNull _d) exitWith {};

private _deg   = sliderPosition 87201;
private _pivot = [(sliderPosition 87202)/100, (sliderPosition 87203)/100, (sliderPosition 87204)/100];
private _lift  = (sliderPosition 87205)/100;
private _voff  = [(sliderPosition 87221)/100, (sliderPosition 87222)/100, (sliderPosition 87223)/100];
private _vp    = sliderPosition 87224;
private _vy    = sliderPosition 87225;
private _vr    = sliderPosition 87226;

missionNamespace setVariable ["ACME_headElev_tiltDeg", _deg];
missionNamespace setVariable ["ACME_headElev_pivotOffset", _pivot];
missionNamespace setVariable ["ACME_headElev_liftZ", _lift];
missionNamespace setVariable ["ACME_headElev_vestPropOffset", _voff, true];
missionNamespace setVariable ["ACME_headElev_vestPropPitch", _vp, true];
missionNamespace setVariable ["ACME_headElev_vestPropYaw", _vy, true];
missionNamespace setVariable ["ACME_headElev_vestPropRoll", _vr, true];

(_d displayCtrl 87211) ctrlSetText format ["Extra Tilt %1 deg", round _deg];
(_d displayCtrl 87212) ctrlSetText format ["Pos X   %1 m", (_pivot#0) toFixed 3];
(_d displayCtrl 87213) ctrlSetText format ["Pos Y   %1 m", (_pivot#1) toFixed 3];
(_d displayCtrl 87214) ctrlSetText format ["Pos Z   %1 m", (_pivot#2) toFixed 3];
(_d displayCtrl 87215) ctrlSetText format ["Lift Z   %1 m", _lift toFixed 3];
(_d displayCtrl 87231) ctrlSetText format ["PC X   %1 m", (_voff#0) toFixed 3];
(_d displayCtrl 87232) ctrlSetText format ["PC Y   %1 m", (_voff#1) toFixed 3];
(_d displayCtrl 87233) ctrlSetText format ["PC Z   %1 m", (_voff#2) toFixed 3];
(_d displayCtrl 87234) ctrlSetText format ["PC Pitch %1", _vp toFixed 1];
(_d displayCtrl 87235) ctrlSetText format ["PC Yaw %1", _vy toFixed 1];
(_d displayCtrl 87236) ctrlSetText format ["PC Roll %1", _vr toFixed 1];

private _patient = missionNamespace getVariable ["ACME_headElev_TunePatient", objNull];
if (!isNull _patient && {_patient getVariable ["ACME_headElevated", false]}) then {
    [_patient, false] call ACME_fnc_headElevApplyTilt;
    [_patient] call ACME_fnc_headElevPropApply;
};
