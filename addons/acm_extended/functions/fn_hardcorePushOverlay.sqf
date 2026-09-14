/* B122: persistent one-handed syringe overlay. Presentation is independent from treatment state. The same overlay
   is painted on the gameplay, ACE interaction-menu, and ACE medical-menu displays so opening Windows interaction
   or the medical GUI cannot hide the active push or make the syringe unclickable. */
disableSerialization;
params [["_mode","update",[""]]];
private _ids = [98970,98971,98972,98973,98974];
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

// The full Narc Box owns the syringe art while open. Flow continues, but the corner duplicate disappears.
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

// Geometry is derived from the real Narc Box syringe canvas captured at push start. This keeps the barrel/plunger
// relationship identical across aspect ratios instead of guessing a second set of offsets for the HUD.
private _aspect = ((_job getOrDefault ["overlayAspect",0.115]) max 0.035) min 0.45;
private _travelNorm = ((_job getOrDefault ["overlayTravelNorm",0.195]) max 0.02) min 0.40;
private _sizeRatio = switch (_size) do {case 1:{10.2/10.5}; case 3:{9.83/10.5}; case 5:{10.3/10.5}; default{1};};
private _frac = ((_remaining / (_size max 0.01)) max 0) min 1;

// Size is anchored to safeZoneH and width follows the captured syringe aspect, so ultrawide and 4:3 use the same
// physical visual scale. B122 enlarges the previous 15.5%-height overlay to 19.5%.
private _h = safeZoneH * 0.195;
private _w = _h * _aspect;
private _travel = _h * _travelNorm * _sizeRatio;
private _right = safeZoneX + safeZoneW - safeZoneW*0.020;
private _x = _right - _w;
private _y = safeZoneY + safeZoneH - _h - _travel - safeZoneH*0.045;

// Text panel uses a height-derived physical width corrected by pixel aspect. It therefore does not become huge on
// 32:9 or cramped on 4:3. Two lines keep the medication name readable without shrinking the syringe itself.
private _tw = ((safeZoneH * 0.50) * (pixelW / (pixelH max 0.000001))) min (safeZoneW*0.32);
private _th = safeZoneH * 0.052;
private _tx = _right - _tw;
private _ty = _y - _th - safeZoneH*0.007;

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
        _bar = _disp ctrlCreate ["RscPictureKeepAspect",98970];
        private _back = _disp ctrlCreate ["RscPictureKeepAspect",98971];
        private _pl = _disp ctrlCreate ["RscPictureKeepAspect",98972];
        private _txt = _disp ctrlCreate ["RscStructuredText",98973];
        private _hit = _disp ctrlCreate ["RscButton",98974];
        _txt ctrlSetBackgroundColor [0.02,0.03,0.06,0.88];
        _txt ctrlSetTextColor [0.94,0.91,0.82,1];
        _hit ctrlSetText "";
        _hit ctrlSetBackgroundColor [0,0,0,0];
        _hit ctrlSetTooltip "Open Narc Box at the active syringe push";
        _hit ctrlAddEventHandler ["ButtonClick",{call ACME_fnc_hardcorePushReopen;}];
    };
    private _back = _disp displayCtrl 98971;
    private _pl = _disp displayCtrl 98972;
    private _txt = _disp displayCtrl 98973;
    private _hit = _disp displayCtrl 98974;

    _bar ctrlSetText _barTex;
    _back ctrlSetText _backTex;
    _pl ctrlSetText _plTex;
    _bar ctrlSetPosition [_x,_y,_w,_h];
    _back ctrlSetPosition [_x,_y,_w,_h];
    _pl ctrlSetPosition [_x,_y + (_travel*_frac),_w,_h];
    _txt ctrlSetPosition [_tx,_ty,_tw,_th];
    _txt ctrlSetFontHeight (_th*0.30);
    _txt ctrlSetStructuredText parseText format [
        "<t align='center' color='#F0E9D1' size='0.92'>%1</t><br/><t align='center' color='#FFFFFF' size='0.78'>%2s / %3s  |  %4 mL remaining</t>",
        _label,_leftSec,_totalSec,_remaining toFixed 2
    ];
    // Click the syringe itself (including the moving plunger), not an invisible screen-wide panel.
    private _padX = (_w*0.45) max (8*pixelW);
    private _padY = (_h*0.04) max (6*pixelH);
    _hit ctrlSetPosition [_x-_padX,_y-_padY,_w+2*_padX,_h+_travel+2*_padY];
    {_x ctrlShow true; _x ctrlCommit 0;} forEach [_bar,_back,_pl,_txt,_hit];
};

private _painted = false;
{
    private _disp = findDisplay _x;
    if (!isNull _disp) then {[_disp] call _paint; _painted = true;};
} forEach _displayIds;
_painted
