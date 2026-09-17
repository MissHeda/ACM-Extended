/* IV tray hover animation.
   Needle slots rotate 90 degrees left at rest. Hover enlarges the front catheter and fans the provider's
   available stock (up to five total needles) like a small deck. >5 adds a + marker. Band/pad only enlarge.
   All dynamic fan controls are input-disabled and collapse/fade back to the slot as soon as hover ends. */
disableSerialization;
params [['_kind','', ['']], ['_gauge',0,[0]], ['_enter',false,[true]]];
private _d = uiNamespace getVariable ['ACME_IV_DLG',displayNull];
if (isNull _d) exitWith {};
private _ease = missionNamespace getVariable ['ACME_iv_trayHoverSec',0.11];
if !(_ease isEqualType 0 && {finite _ease} && {_ease >= 0}) then {_ease = 0.11;};

private _scaleRect = {
    params ['_r','_mul'];
    _r params ['_x','_y','_w','_h'];
    private _nw = _w * _mul;
    private _nh = _h * _mul;
    [_x + ((_w-_nw)*0.5), _y + ((_h-_nh)*0.5), _nw, _nh]
};

if (_kind in ['band','pad']) exitWith {
    private _idc = if (_kind == 'band') then {86531} else {86536};
    private _ctrl = _d displayCtrl _idc;
    if (isNull _ctrl) exitWith {};
    private _key = format ['ACME_IV_TrayBase_%1',_idc];
    private _base = _d getVariable [_key,[]];
    if (_base isEqualTo []) then {_base = ctrlPosition _ctrl; _d setVariable [_key,+_base];};
    _ctrl ctrlSetPosition ([_base, if (_enter) then {1.10} else {1}] call _scaleRect);
    _ctrl ctrlCommit _ease;
};
if (_kind != 'needle' || {!(_gauge in [14,16,18,20])}) exitWith {};

private _rec = [];
{
    if ((_x param [0,-1]) == _gauge) exitWith {_rec = _x;};
} forEach (uiNamespace getVariable ['ACME_IV_NeedleRects',[]]);
if (count _rec < 4) exitWith {};
_rec params ['','_slot','_base','_logoIdc'];
private _logo = _d displayCtrl _logoIdc;
if (isNull _logo) exitWith {};

private _medic = uiNamespace getVariable ['ACME_IV_Medic',objNull];
private _count = if (isNull _medic) then {0} else {[_medic,format ['ACM_IV_%1g',_gauge]] call ace_common_fnc_getCountOfItem};
private _shown = (_count min 5) max 0;
private _colors = createHashMapFromArray [
    [14,[1,0.55,0.55,0.84]],
    [16,[1,1,1,0.84]],
    [18,[0.70,0.90,1,0.84]],
    [20,[0.60,0.85,1,0.84]]
];
private _fanKey = format ['ACME_IV_TrayFan_%1',_gauge];
private _fan = _d getVariable [_fanKey,[]];
if (_fan isEqualTo []) then {
    // Four copies + the real front logo = five total needles maximum.
    for '_i' from 0 to 3 do {
        private _c = _d ctrlCreate ['RscPictureKeepAspect',-1];
        _c ctrlSetText (ctrlText _logo);
        _c ctrlSetTextColor (_colors getOrDefault [_gauge,[1,1,1,0.84]]);
        _c ctrlSetPosition _base;
        _c ctrlSetAngle [-90,0.5,0.5,false];
        _c ctrlSetFade 1;
        _c ctrlEnable false;
        _c ctrlCommit 0;
        _fan pushBack _c;
    };
    private _plus = _d ctrlCreate ['RscText',-1];
    _plus ctrlSetText '+';
    _plus ctrlSetFont 'RobotoCondensed';
    _plus ctrlSetTextColor [0.94,0.91,0.82,1];
    _plus ctrlSetBackgroundColor [0,0,0,0];
    _plus ctrlSetFade 1;
    _plus ctrlEnable false;
    _plus ctrlCommit 0;
    _fan pushBack _plus;
    _d setVariable [_fanKey,_fan];
};
private _plus = _fan param [4,controlNull];

// Primary catheter always grows slightly on hover; it is one of the displayed inventory needles.
_logo ctrlSetPosition ([_base, if (_enter && {_shown > 0}) then {1.11} else {1}] call _scaleRect);
_logo ctrlSetAngle [-90,0.5,0.5,false];
_logo ctrlCommit _ease;

_slot params ['_sx','_sy','_sw','_sh'];
// Fan offsets/angles are ordered centre-out so fewer than five remain visually balanced.
private _poses = [
    [-0.18, 0.08, -106],
    [-0.09, 0.035, -98],
    [ 0.09, 0.035, -82],
    [ 0.18, 0.08, -74]
];
private _cloneCount = ((_shown - 1) max 0) min 4;
for '_i' from 0 to 3 do {
    private _c = _fan select _i;
    if (_enter && {_i < _cloneCount}) then {
        (_poses select _i) params ['_ox','_oy','_ang'];
        private _r = [_base,1.07] call _scaleRect;
        _r params ['_x','_y','_w','_h'];
        _c ctrlSetPosition [_x + (_sw*_ox), _y + (_sh*_oy), _w, _h];
        _c ctrlSetAngle [_ang,0.5,0.5,false];
        _c ctrlSetFade 0;
        _c ctrlCommit _ease;
    } else {
        _c ctrlSetPosition _base;
        _c ctrlSetAngle [-90,0.5,0.5,false];
        _c ctrlSetFade 1;
        _c ctrlCommit _ease;
    };
};

if (!isNull _plus) then {
    private _pw = _sw * 0.32;
    private _ph = _sh * 0.34;
    _plus ctrlSetPosition [_sx + (_sw*0.78), _sy - (_sh*0.04), _pw, _ph];
    _plus ctrlSetFontHeight (_ph * 0.72);
    _plus ctrlSetFade (if (_enter && {_count > 5}) then {0} else {1});
    _plus ctrlCommit _ease;
};
