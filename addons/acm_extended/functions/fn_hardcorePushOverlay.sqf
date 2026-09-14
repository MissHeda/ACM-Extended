/* B124: persistent one-handed syringe HUD. Treatment state is independent from display state. The HUD is
   rebuilt on the gameplay/ACE displays as needed and uses the same square PAA canvas geometry as ACM's native
   syringe so the barrel, backbit and moving plunger stay aligned on every aspect ratio. */
disableSerialization;
params [["_mode","update",[""]]];
private _ids = [98970,98971,98972,98973,98974,98975];
private _displayIds = [46,91919,38580];
private _clear = {
    {
        private _disp = findDisplay _x;
        if (!isNull _disp) then {
            {
                private _c = _disp displayCtrl _x;
                if (!isNull _c) then {ctrlDelete _c;};
            } forEach _ids;
        };
    } forEach _displayIds;
};
if (_mode == "clear") exitWith {call _clear; true};

private _job = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
if !(_job isEqualType createHashMap && {count _job > 0} && {_job getOrDefault ["flowing",false]}) exitWith {
    call _clear;
    false
};

// The full Narc Box owns the syringe art while it is open. Flow continues without the duplicate corner HUD.
if (!isNull (findDisplay 84000)) exitWith {call _clear; true};

private _medic = _job getOrDefault ["medic",objNull];
private _stable = _job getOrDefault ["stableId",""];
private _remaining = 0;
if (!isNull _medic && {_stable != ""}) then {
    private _store = _medic getVariable ["ACME_narcStore",[]];
    private _ix = _store findIf {(_x param [11,"",[""]]) == _stable};
    if (_ix >= 0) then {
        private _r = _store select _ix;
        _remaining = ((_r param [2,0,[0]]) + (_r param [4,0,[0]])) max 0;
    };
};

private _size = _job getOrDefault ["size",10];
if !(_size in [1,3,5,10]) then {_size = 10;};
private _marker = _job getOrDefault ["barrelMarker",""];
private _barTex = if (_marker == "flush") then {
    "\acm_extended\ui\syringe\syringe_flush_10_barrel_ca.paa"
} else {
    format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_barrel_ca.paa",_size]
};
private _backTex = format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_backbit_ca.paa",_size];
private _plTex = format ["\x\ACM\addons\circulation\ui\syringe\syringe_%1_plunger_ca.paa",_size];

private _travelNorm = ((_job getOrDefault ["overlayTravelNorm",0.195]) max 0.02) min 0.40;
private _sizeRatio = switch (_size) do {case 1:{10.2/10.5}; case 3:{9.83/10.5}; case 5:{10.3/10.5}; default{1};};
private _frac = ((_remaining / (_size max 0.01)) max 0) min 1;

// The PAA layers live on a square canvas. Convert vertical GUI units to the exact width that gives the same number
// of physical pixels horizontally. This prevents the ultrawide squashing that made the syringe effectively vanish.
private _pxAspect = pixelW / (pixelH max 0.000001);
private _h = safeZoneH * 0.245;
private _w = _h * _pxAspect;
private _travel = _h * _travelNorm * _sizeRatio;
private _padScreen = safeZoneH * 0.028;
private _right = safeZoneX + safeZoneW - (_padScreen * _pxAspect);
private _bottom = safeZoneY + safeZoneH - _padScreen;
private _x = _right - _w;
private _y = _bottom - _h - _travel;

// Compact two-line label, right aligned with the syringe. Width is height-derived so it stays the same physical
// size on 4:3, 16:9, 21:9 and 32:9 rather than stretching with safeZoneW.
private _tw = safeZoneH * 0.40 * _pxAspect;
private _th = safeZoneH * 0.062;
private _tx = _right - _tw;
private _ty = _y - _th - safeZoneH*0.010;

private _rate = (_job getOrDefault ["rateMlSec",0]) max 0;
private _totalSec = ceil ((_job getOrDefault ["duration",0]) max 0);
private _targetLeft = ((_job getOrDefault ["targetMl",0]) - (_job getOrDefault ["pushedMl",0])) max 0;
private _leftSec = if (_rate > 0.000001) then {ceil (_targetLeft / _rate)} else {0};
_leftSec = (_leftSec max 0) min (_totalSec max 0);
private _label = _job getOrDefault ["pushLabel",_job getOrDefault ["med","Medication"]];
if (_label == "") then {_label = "Medication";};

private _paint = {
    params ["_disp"];
    if (isNull _disp) exitWith {};

    private _bar = _disp displayCtrl 98970;
    if (isNull _bar) then {
        // Native order is backbit -> plunger -> barrel. Keep the same z-order so the barrel remains visible.
        private _back = _disp ctrlCreate ["RscPicture",98971];
        private _pl = _disp ctrlCreate ["RscPicture",98972];
        _bar = _disp ctrlCreate ["RscPicture",98970];
        private _panel = _disp ctrlCreate ["RscText",98975];
        private _txt = _disp ctrlCreate ["RscStructuredText",98973];
        private _hit = _disp ctrlCreate ["RscButton",98974];
        {_x ctrlSetTextColor [1,1,1,1];} forEach [_back,_pl,_bar];
        _panel ctrlSetBackgroundColor [0.02,0.03,0.06,0.90];
        _panel ctrlEnable false;
        _txt ctrlSetBackgroundColor [0,0,0,0];
        _txt ctrlSetTextColor [0.94,0.91,0.82,1];
        _txt ctrlEnable false;
        _hit ctrlSetText "";
        _hit ctrlSetBackgroundColor [0,0,0,0];
        _hit ctrlSetTooltip "Open Narc Box at the active syringe push";
        _hit ctrlAddEventHandler ["ButtonClick",{call ACME_fnc_hardcorePushReopen;}];
    };

    private _back = _disp displayCtrl 98971;
    private _pl = _disp displayCtrl 98972;
    private _txt = _disp displayCtrl 98973;
    private _hit = _disp displayCtrl 98974;
    private _panel = _disp displayCtrl 98975;

    _back ctrlSetText _backTex;
    _pl ctrlSetText _plTex;
    _bar ctrlSetText _barTex;
    _back ctrlSetPosition [_x,_y,_w,_h];
    _pl ctrlSetPosition [_x,_y + (_travel*_frac),_w,_h];
    _bar ctrlSetPosition [_x,_y,_w,_h];

    _panel ctrlSetPosition [_tx,_ty,_tw,_th];
    // Give StructuredText explicit internal top/bottom padding so both lines sit visually centered in the bar.
    _txt ctrlSetPosition [_tx,_ty + _th*0.10,_tw,_th*0.82];
    _txt ctrlSetFontHeight (_th*0.43);
    _txt ctrlSetStructuredText parseText format [
        "<t align='center' color='#F0E9D1' size='1.02'>%1</t><br/><t align='center' color='#FFFFFF' size='0.90'>%2s / %3s  |  %4 mL</t>",
        _label,_leftSec,_totalSec,_remaining toFixed 2
    ];

    // Click the visible syringe/plunger stack. Keep the label separate so a Windows-key menu cannot steal this hitbox.
    private _padX = (_w*0.18) max (8*pixelW);
    private _padY = (_h*0.035) max (6*pixelH);
    _hit ctrlSetPosition [_x-_padX,_y-_padY,_w+2*_padX,_h+_travel+2*_padY];
    {_x ctrlShow true; _x ctrlCommit 0;} forEach [_back,_pl,_bar,_panel,_txt,_hit];
};

private _painted = false;
{
    private _disp = findDisplay _x;
    if (!isNull _disp) then {[_disp] call _paint; _painted = true;};
} forEach _displayIds;
_painted
