/* B121: small one-handed syringe display on the main game UI. The overlay is presentation only: creating,
   deleting, clicking, opening or closing a menu never starts/stops flow. */
disableSerialization;
params [["_mode","update",[""]]];
private _ids = [98970,98971,98972,98973,98974];
private _clear = {
    private _main = findDisplay 46;
    if (!isNull _main) then {{private _c = _main displayCtrl _x; if (!isNull _c) then {ctrlDelete _c;};} forEach _ids;};
};
if (_mode == "clear") exitWith {call _clear; true};
private _job = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
if !(_job isEqualType createHashMap && {count _job > 0} && {_job getOrDefault ["flowing",false]}) exitWith {call _clear; false};
// The full Narc Box owns the syringe art while open. Never layer a second clickable syringe over it.
if (!isNull (findDisplay 84000)) exitWith {call _clear; true};
private _main = findDisplay 46;
if (isNull _main) exitWith {false};
private _bar = _main displayCtrl 98970;
if (isNull _bar) then {
    _bar = _main ctrlCreate ["RscPictureKeepAspect",98970];
    private _back = _main ctrlCreate ["RscPictureKeepAspect",98971];
    private _pl = _main ctrlCreate ["RscPictureKeepAspect",98972];
    private _txt = _main ctrlCreate ["RscText",98973];
    private _hit = _main ctrlCreate ["RscButton",98974];
    _txt ctrlSetBackgroundColor [0.02,0.03,0.06,0.82];
    _txt ctrlSetTextColor [0.94,0.91,0.82,1];
    _hit ctrlSetText "";
    _hit ctrlSetBackgroundColor [0,0,0,0];
    _hit ctrlSetTooltip "Open Narc Box at the active syringe push";
    _hit ctrlAddEventHandler ["ButtonClick",{call ACME_fnc_hardcorePushReopen;}];
};
private _back = _main displayCtrl 98971;
private _pl = _main displayCtrl 98972;
private _txt = _main displayCtrl 98973;
private _hit = _main displayCtrl 98974;
private _size = _job getOrDefault ["size",10];
if !(_size in [1,3,5,10]) then {_size = 10;};
private _marker = _job getOrDefault ["barrelMarker",""];
private _barTex = if (_marker == "flush") then {"\acm_extended\ui\syringe\syringe_flush_10_barrel_ca.paa"} else {format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_barrel_ca.paa",_size]};
_bar ctrlSetText _barTex;
_back ctrlSetText format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_backbit_ca.paa",_size];
_pl ctrlSetText format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_plunger_ca.paa",_size];
private _h = safeZoneH * 0.155;
private _w = _h * 0.205;
private _x = safeZoneX + safeZoneW - _w - safeZoneW*0.024;
private _y = safeZoneY + safeZoneH - _h - safeZoneH*0.075;
private _medic = _job getOrDefault ["medic",objNull];
private _stable = _job getOrDefault ["stableId",""];
private _remaining = 0;
if (!isNull _medic && {_stable != ""}) then {
    private _store = _medic getVariable ["ACME_narcStore",[]];
    private _ix = _store findIf {(_x param [11,"",[""]]) == _stable};
    if (_ix >= 0) then {private _r = _store select _ix; _remaining = ((_r param [2,0,[0]]) + (_r param [4,0,[0]])) max 0;};
};
private _frac = ((_remaining / ((_size max 0.01))) max 0) min 1;
private _travel = _h * 0.195 * (switch (_size) do {case 1:{10.2/10.5};case 3:{9.83/10.5};case 5:{10.3/10.5};default{1};});
_bar ctrlSetPosition [_x,_y,_w,_h];
_back ctrlSetPosition [_x,_y,_w,_h];
_pl ctrlSetPosition [_x,_y + _travel*_frac,_w,_h];
private _tw = safeZoneW*0.115; private _th = safeZoneH*0.031;
_txt ctrlSetPosition [_x + _w/2 - _tw/2,_y-_th-safeZoneH*0.004,_tw,_th];
_txt ctrlSetFontHeight (_th*0.58);
private _rate = (_job getOrDefault ["rateMlSec",0]) max 0;
_txt ctrlSetText format ["Pushing  %1 mL  |  %2 mL/s",_remaining toFixed 2,_rate toFixed 3];
_hit ctrlSetPosition [_x-_w*0.35,_y-_th,_w*1.7,_h+_th*1.5];
{_x ctrlShow true; _x ctrlCommit 0;} forEach [_bar,_back,_pl,_txt,_hit];
true
