// Park carriers removed for the chest-seal workspace at fixed world-space points.
// Each prop captures its target once and stays there; patient rolls/lifts never make it chase the head.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {};

private _props = [];
private _chestProp = _patient getVariable ["ACME_CS_vestProp", objNull];
if (!isNull _chestProp) then {_props pushBackUnique _chestProp;};
private _headProp = _patient getVariable ["ACME_headElev_propObj", objNull];
if ((_patient getVariable ["ACME_CS_ProcedureActive", false]) && {!isNull _headProp}) then {
    _props pushBackUnique _headProp;
};
if (_props isEqualTo []) exitWith {};

private _needsInitialPark = (_props findIf {(count (_x getVariable ["ACME_chestFixedPark", []])) != 3}) >= 0;
if (!_needsInitialPark) exitWith {
    {
        detach _x;
        _x disableCollisionWith _patient;
        _patient disableCollisionWith _x;
    } forEach _props;
};

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
private _side = [-(_axis select 1), _axis select 0, 0];
private _baseGap = missionNamespace getVariable ["ACME_headElev_propGroundGap", 0.45];
private _gap = (missionNamespace getVariable ["ACME_chestAccessCarrierGap", 0.85]) max _baseGap;
private _ease = missionNamespace getVariable ["ACME_headElev_propEaseTime", 0.24];

{
    private _prop = _x;
    detach _prop;
    _prop disableCollisionWith _patient;
    _patient disableCollisionWith _prop;

    private _park = _prop getVariable ["ACME_chestFixedPark", []];
    if ((count _park) != 3) then {
        private _lane = (_forEachIndex * 0.24) - (((count _props) - 1) * 0.12);
        private _px = (_hed select 0) + ((_axis select 0) * _gap) + ((_side select 0) * _lane);
        private _py = (_hed select 1) + ((_axis select 1) * _gap) + ((_side select 1) * _lane);
        private _target = [_px, _py, 0.02];
        private _up = surfaceNormal [_px, _py];
        _park = [_target, +_axis, +_up];
        _prop setVariable ["ACME_chestFixedPark", _park, false];
        [_prop, _target, _axis, _up, _ease] call ACME_fnc_propEaseTo;
    };
} forEach _props;
