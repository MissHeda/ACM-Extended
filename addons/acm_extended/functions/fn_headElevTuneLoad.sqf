params ["_display"];
private _deg   = missionNamespace getVariable ["ACME_headElev_tiltDeg", 30];
private _pivot = missionNamespace getVariable ["ACME_headElev_pivotOffset", [0, 0.55, 0]];
private _lift  = missionNamespace getVariable ["ACME_headElev_liftZ", 0.18];
private _voff  = missionNamespace getVariable ["ACME_headElev_vestPropOffset", [-0.0624309, 0.327775, -0.262297]];
private _vp    = missionNamespace getVariable ["ACME_headElev_vestPropPitch", -180];
private _vy    = missionNamespace getVariable ["ACME_headElev_vestPropYaw", -9.52483];
private _vr    = missionNamespace getVariable ["ACME_headElev_vestPropRoll", 0];
{
    _x params ["_idc","_min","_max","_val","_step","_page"];
    private _c = _display displayCtrl _idc;
    _c sliderSetRange [_min,_max];
    _c sliderSetSpeed [_step,_page];
    _c sliderSetPosition _val;
} forEach [
    [87201,   0,  60, _deg,          1, 5],
    [87202,-200, 200, (_pivot#0)*100, 1, 10],
    [87203,-200, 200, (_pivot#1)*100, 1, 10],
    [87204,-200, 200, (_pivot#2)*100, 1, 10],
    [87205,-100, 100, _lift*100,      1, 10],
    [87221,-100, 100, (_voff#0)*100,  1, 5],
    [87222,-100, 100, (_voff#1)*100,  1, 5],
    [87223,-100, 100, (_voff#2)*100,  1, 5],
    [87224,-180, 180, _vp,            0.5, 15],
    [87225,-180, 180, _vy,            0.5, 15],
    [87226,-180, 180, _vr,            0.5, 15]
];
[] call ACME_fnc_headElevTuneUpdate;
