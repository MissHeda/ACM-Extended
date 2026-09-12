// build the bottom nav chevron strip, confirm, home, back and next, for a vent screen, and register the visible
// ones as ACME_vent_navList so the dial can traverse exactly them.
// call it as [[_confirm, _home, _back, _next]] call ACME_fnc_ventNavStrip.
// it is extracted from the list-screen flow, so the custom screens, ALERTS 1/2 and ALERTS 2/2, get the same
// chevrons the list screens do. without this a custom screen has no back button and you cannot leave it, which is
// exactly what happened to PARAMS and ALERTS when they became custom-drawn.
params [["_nav", [false,true,false,false]]];
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};
(uiNamespace getVariable ["ACME_vent_scrRect", [0,0,1,1]]) params ["_sx","_sy","_sw","_sh"];

_nav params ["_showConfirm","_showHome","_showBack","_showNext"];
private _navFlags = [_showConfirm,_showHome,_showBack,_showNext];
private _navPairs = [[87790,87791],[87792,87793],[87794,87795],[87796,87797]];
private _navMeta  = [["confirm",87790,87791],["home",87792,87793],["back",87794,87795],["next",87796,87797]];
private _navHlIdc = [87754, 87755, 87756, 87757];
private _navY = 0.885; private _navH = 0.10;
private _icoPx = (_navH * _sh) / pixelH * 0.72;
private _icoW = _icoPx * pixelW; private _icoH = _icoPx * pixelH;
// the slot and hover order.
// next sits on the left of the strip now and is the first nav icon the dial reaches after the last list row, so
// paging through a multi-page screen is a continuous downward motion instead of having to travel across the whole
// strip to reach the page control. BACK moves to the right corner at the standard padding, which also tidies the
// bottom row, and home stays centerd between them.
// confirm keeps the left slot too. no screen in the device shows confirm and next at the same time, because
// confirm belongs to the setup flow and next to the paged menus, so they cannot collide.
// the slot x values are 0.06 for next and confirm, on the left, 0.40 for home, in the center, and 0.86 for back, in
// the right corner. the hover order is next, then confirm, then home, then back.
private _slotFor  = createHashMapFromArray [["confirm", 0.06], ["home", 0.40], ["back", 0.86], ["next", 0.06]];
private _hoverOrder = ["next", "confirm", "home", "back"];

private _visibleNav = [];
{
    _x params ["_btnIdc","_icoIdc"];
    private _show = _navFlags select _forEachIndex;
    private _btn = _dlg displayCtrl _btnIdc;
    private _ico = _dlg displayCtrl _icoIdc;
    private _hl  = _dlg displayCtrl (_navHlIdc select _forEachIndex);
    if (_show) then {
        private _slotX = _slotFor getOrDefault [((_navMeta select _forEachIndex) select 0), 0.40];
        _btn ctrlSetPosition [_sx + _sw*_slotX, _sy + _sh*_navY, _sw*0.14, _sh*_navH];
        _btn ctrlCommit 0;
        private _cellCx = _sx + _sw*(_slotX + 0.07);
        private _icoYabs = _sy + _sh*_navY + (_sh*_navH - _icoH)/2;
        _ico ctrlSetPosition [_cellCx - _icoW/2, _icoYabs, _icoW, _icoH];
        _ico ctrlCommit 0;
        private _hlPad = _icoW * 0.25;
        _hl ctrlSetPosition [_cellCx - _icoW/2 - _hlPad, _icoYabs - (_icoH*0.15), _icoW + 2*_hlPad, _icoH*1.3];
        _hl ctrlSetBackgroundColor ([[0,0,0,0]] call ACME_fnc_ventColor);
        _hl ctrlCommit 0;
        _btn ctrlShow true; _ico ctrlShow true; _hl ctrlShow true;
        _visibleNav pushBack [(_navMeta select _forEachIndex) select 0, _navHlIdc select _forEachIndex];
    } else {
        _btn ctrlShow false; _ico ctrlShow false; _hl ctrlShow false;
    };
} forEach _navPairs;
// re-sort into the hover order the dial should walk, independent of the order the controls were placed in.
private _ordered = [];
{
    private _want = _x;
    private _hit = _visibleNav findIf { (_x select 0) isEqualTo _want };
    if (_hit >= 0) then { _ordered pushBack (_visibleNav select _hit); };
} forEach _hoverOrder;
uiNamespace setVariable ["ACME_vent_navList", _ordered];
