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
// Always derive the hover geometry from the LIVE tray background control. The resting catheter logo intentionally
// uses an oversized transparent canvas so the catheter itself fills the slot after rotation; reusing that canvas for
// fan copies makes the deck look stretched and makes screen-space badges drift away from the slot.
private _bgIdc = switch (_gauge) do {case 14:{86540}; case 16:{86544}; case 18:{86548}; default {86556};};
private _bg = _d displayCtrl _bgIdc;
if (!isNull _bg) then {
    private _liveSlot = ctrlPosition _bg;
    if ((count _liveSlot) >= 4) then {_slot = +_liveSlot;};
};

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
// The fan gets its OWN compact canvas inside the tray box. Do not reuse _base: _base is deliberately much larger
// than the box to compensate for transparent padding in the source catheter art.
private _fanW = _sw * 0.88;
private _fanH = _sh * 0.70;
private _fanX = _sx + ((_sw - _fanW) * 0.5);
private _fanY = _sy + ((_sh - _fanH) * 0.5);
private _fanBase = [_fanX,_fanY,_fanW,_fanH];
// Tight deck-style splay. The prior +/-16 degree fan read like a stretched triangle; keep the copies mostly stacked
// under the real front catheter and use tiny offsets so the entire animation remains part of this one tray tile.
private _poses = [
    [-0.030, 0.045, -100],
    [-0.012, 0.020,  -95],
    [ 0.012, 0.020,  -85],
    [ 0.030, 0.045,  -80]
];
private _cloneCount = ((_shown - 1) max 0) min 4;
for '_i' from 0 to 3 do {
    private _c = _fan select _i;
    if (_enter && {_i < _cloneCount}) then {
        (_poses select _i) params ['_ox','_oy','_ang'];
        _c ctrlSetPosition [_fanX + (_sw*_ox), _fanY + (_sh*_oy), _fanW, _fanH];
        _c ctrlSetAngle [_ang,0.5,0.5,false];
        _c ctrlSetFade 0;
        _c ctrlCommit _ease;
    } else {
        _c ctrlSetPosition _fanBase;
        _c ctrlSetAngle [-90,0.5,0.5,false];
        _c ctrlSetFade 1;
        _c ctrlCommit _ease;
    };
};

if (!isNull _plus) then {
    // Badge is explicitly inset from the live tray box top-right corner. This keeps it inside the tile on every
    // aspect ratio/UI scale instead of letting a stale cached rect place it in the middle of the screen.
    private _pw = _sw * 0.22;
    private _ph = _sh * 0.28;
    private _px = _sx + _sw - _pw - (_sw * 0.035);
    private _py = _sy + (_sh * 0.025);
    _plus ctrlSetPosition [_px,_py,_pw,_ph];
    _plus ctrlSetFontHeight (_sh * 0.23);
    _plus ctrlSetFade (if (_enter && {_count > 5}) then {0} else {1});
    _plus ctrlCommit _ease;
};
