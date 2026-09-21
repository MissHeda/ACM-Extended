// Park temporarily removed chest-access carriers at one fixed world-space point beyond the casualty's head.
// The target is captured ONCE per prop. Later patient lifts, rolls or head motion never drag the carrier around.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {};

private _props = [];
private _chestProp = _patient getVariable ["ACME_chestAccess_vestProp", objNull];
if (!isNull _chestProp) then {_props pushBackUnique _chestProp;};

// Semi-Fowler may already own a second removed carrier/support prop. It receives its own fixed slot.
private _headProp = _patient getVariable ["ACME_headElev_propObj", objNull];
private _chestLeases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
if ((!isNull _headProp)
    && {(_patient getVariable ["ACME_headElev_Suspended", false]) || {count _chestLeases > 0}}) then {
    _props pushBackUnique _headProp;
};
if (_props isEqualTo []) exitWith {};

// Once every prop has a fixed target, this function deliberately stops consulting the casualty's head/body pose.
// Repeated custody/watchdog calls therefore cannot make a parked carrier follow a rolling or lifted patient.
private _needsInitialPark = (_props findIf {(count (_x getVariable ["ACME_chestFixedPark", []])) != 3}) >= 0;
if (!_needsInitialPark) exitWith {
    {
        detach _x;
        _x disableCollisionWith _patient;
        _patient disableCollisionWith _x;
    } forEach _props;
};

// Compute the candidate park direction once for any prop that has not yet been parked. A generous fixed gap keeps
// the carrier clear even while the casualty subsequently lowers from the temporary lift.
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
