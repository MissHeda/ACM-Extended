/* Pan only the patient layers of an enlarged IV view. Up/Down leaves the tray,
   buttons and cursor fixed, while persisted UV coordinates remain unchanged. */
disableSerialization;
params [["_direction", 0, [0]]];
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg || {!([] call ACME_fnc_ivUiValid)}) exitWith {};
// Panning cannot become mouse travel during an active wipe, push or pull.
if (uiNamespace getVariable ["ACME_IV_Dragging", false]) exitWith {};
private _base = uiNamespace getVariable ["ACME_IV_BodyRectBase", []];
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", []];
if (count _base < 4 || {count _rect < 4}) exitWith {};
_base params ["_bx", "_by", "_bw", "_bh"];
private _top = safeZoneY + safeZoneH * 0.045;
private _bottom = safeZoneY + safeZoneH * 0.97;
if (_bh <= (_bottom - _top)) exitWith {};
private _nextY = ((_by + _direction * safeZoneH * 0.045) max (_bottom - _bh)) min _top;
private _dy = _nextY - _by;
if (abs _dy < 1e-6) exitWith {};
private _shift = {
    params ["_ctrl", "_dy"];
    if (isNull _ctrl) exitWith {};
    private _p = ctrlPosition _ctrl;
    _p set [1, (_p select 1) + _dy];
    _ctrl ctrlSetPosition _p;
    _ctrl ctrlCommit 0;
};
// Move each patient control once, including hidden prep on the reverse face.
private _ctrls = [86501,86502,86510] apply {_dlg displayCtrl _x};
_ctrls append (uiNamespace getVariable ["ACME_IV_MarkCtrls", []]);
{
    _ctrls pushBack (uiNamespace getVariable [_x,controlNull]);
} forEach ["ACME_IV_CathCtrl", "ACME_IV_CathGhost", "ACME_IV_DotCtrl", "ACME_IV_PipCtrl", "ACME_IV_CleanCtrl", "ACME_IV_PrepBruise"];
{_ctrls pushBack (_x param [0,controlNull]);} forEach (uiNamespace getVariable ["ACME_IV_PrepCtrls", []]);
{
    {_ctrls pushBack (_x param [0,controlNull]);} forEach (_y param [0,[]]);
    _ctrls pushBack (_y param [4,controlNull]);
} forEach (_dlg getVariable ["ACME_IV_PrepViews", createHashMap]);
{[_x,_dy] call _shift;} forEach (_ctrls arrayIntersect _ctrls);
_base set [1,_nextY];
_rect set [1,(_rect select 1) + _dy];
uiNamespace setVariable ["ACME_IV_BodyRectBase", _base];
uiNamespace setVariable ["ACME_IV_BodyRect", _rect];
// Do not reinterpret a held instrument's old screen coordinate as new skin.
uiNamespace setVariable ["ACME_IV_PrepLast", []];
uiNamespace setVariable ["ACME_IV_NeedleTipPos", []];
uiNamespace setVariable ["ACME_IV_NeedleTipUV", []];
uiNamespace setVariable ["ACME_IV_PadPos", []];
uiNamespace setVariable ["ACME_IV_LastNeedleState", []];
// Inserted instruments keep their UV/angle. Raw mouse pins rebase on the next
// push/pull, rather than interpreting the UI translation as needle movement.
uiNamespace setVariable ["ACME_IV_InsPin", []];
uiNamespace setVariable ["ACME_IV_PullPin", []];
private _topLeft = uiNamespace getVariable ["ACME_IV_StickTopLeft", []];
if (count _topLeft >= 2) then {_topLeft set [1,(_topLeft select 1) + _dy]; uiNamespace setVariable ["ACME_IV_StickTopLeft", _topLeft];};
