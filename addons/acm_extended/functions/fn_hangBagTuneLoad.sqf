params ["_display"];
private _off = missionNamespace getVariable ["ACME_hang_handOffset", [-0.171827,-0.0742273,-0.00905121]];
private _rot = missionNamespace getVariable ["ACME_hang_bagEuler", [-110.246,67.3435,179.392]];
private _lineEnd = missionNamespace getVariable ["ACME_hang_linePatientOffset", [0.399215,-0.0718271,0.12404]];
private _lineRot = missionNamespace getVariable ["ACME_hang_linePatientEuler", [-186.934,-84.1472,180]];

{
    _x params ["_idc","_min","_max","_val","_step","_page"];
    private _c = _display displayCtrl _idc;
    _c sliderSetRange [_min,_max];
    _c sliderSetSpeed [_step,_page];
    _c sliderSetPosition _val;
} forEach [
    [87101,-500,500,(_off#0)*100,1,25],
    [87102,-500,500,(_off#1)*100,1,25],
    [87103,-500,500,(_off#2)*100,1,25],
    [87104,-360,360,_rot#0,1,15],
    [87105,-360,360,_rot#1,1,15],
    [87106,-360,360,_rot#2,1,15],
    [87107,-500,500,(_lineEnd#0)*100,1,25],
    [87108,-500,500,(_lineEnd#1)*100,1,25],
    [87109,-500,500,(_lineEnd#2)*100,1,25],
    [87120,-360,360,_lineRot#0,1,15],
    [87121,-360,360,_lineRot#1,1,15],
    [87122,-360,360,_lineRot#2,1,15]
];
[] call ACME_fnc_hangBagTuneUpdate;
