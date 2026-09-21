// Keep every temporarily removed chest-access carrier safely beyond the casualty's head.
// This runs repeatedly while chest access is active so patient rolls/lifts cannot leave a carrier clipping the skull.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {};

private _props = [];
private _chestProp = _patient getVariable ["ACME_chestAccess_vestProp", objNull];
if (!isNull _chestProp) then {_props pushBackUnique _chestProp;};

// Semi-Fowler may own a second removed carrier/support prop while the chest is temporarily laid flat.
private _headProp = _patient getVariable ["ACME_headElev_propObj", objNull];
private _chestLeases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
if ((!isNull _headProp)
    && {(_patient getVariable ["ACME_headElev_Suspended", false]) || {count _chestLeases > 0}}) then {
    _props pushBackUnique _headProp;
};
if (_props isEqualTo []) exitWith {};

private _pel = _patient modelToWorldVisual (_patient selectionPosition "pelvis");
private _hed = _patient modelToWorldVisual (_patient selectionPosition "head");
private _dx = (_hed select 0) - (_pel select 0);
private _dy = (_hed select 1) - (_pel select 1);
private _mag = sqrt ((_dx * _dx) + (_dy * _dy));
if (_mag < 0.05) then {
    private _dir = getDir _patient;
    _dx = sin _dir;
    _dy = cos _dir;
    _mag = 1;
};
private _axis = [_dx / _mag, _dy / _mag, 0];
private _baseGap = missionNamespace getVariable ["ACME_headElev_propGroundGap", 0.45];
private _gap = (missionNamespace getVariable ["ACME_chestAccessCarrierGap", 0.62]) max _baseGap;
private _px = (_hed select 0) + ((_axis select 0) * _gap);
private _py = (_hed select 1) + ((_axis select 1) * _gap);
private _target = [_px, _py, 0.02];
private _up = surfaceNormal [_px, _py];
private _ease = missionNamespace getVariable ["ACME_headElev_propEaseTime", 0.24];

{
    detach _x;
    _x disableCollisionWith _patient;
    _patient disableCollisionWith _x;
    // Do not restart the easing PFH every park tick. Re-seat only after the body has moved enough to matter.
    if ((getPosATL _x) distance _target > 0.06) then {
        [_x, _target, _axis, _up, _ease] call ACME_fnc_propEaseTo;
    } else {
        _x setVectorDirAndUp [_axis, _up];
    };
} forEach _props;
