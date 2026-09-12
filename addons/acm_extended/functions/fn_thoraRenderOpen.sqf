// render the tract opening for the current side from pre-baked rotated frames.
// "" is nothing, meaning the incision only.
// "split" is the pink pleura bed only, because the right-click split reveals the pleura.
// "kelly" is the pleura plus a small dark hole inside it.
// "finger" is the pleura plus a wider dark hole inside it.
// everything rotates to the incision angle, and the dark holes are sized to stay inside the pleura.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};
private _pool = uiNamespace getVariable ["ACME_Thora_OpenSegs", []];
private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
if (count _rect != 4) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
private _state = if (isNull _patient) then { "" } else { _patient getVariable [format ["ACME_thora_open_%1", _side], ""] };
private _inc = if (isNull _patient) then { [] } else { _patient getVariable [format ["ACME_thora_incision_%1", _side], []] };
private _openCtrl = uiNamespace getVariable ["ACME_Thora_OpenCtrl", controlNull];
private _pleuraCtrl = uiNamespace getVariable ["ACME_Thora_PleuraCtrl", controlNull];
{ _x ctrlShow false } forEach _pool;

if (_state isEqualTo "" || {count _inc != 3}) exitWith {
    if (!isNull _openCtrl) then { _openCtrl ctrlShow false; };
    if (!isNull _pleuraCtrl) then { _pleuraCtrl ctrlShow false; };
};

_inc params ["_ist", "_iang", "_ilenCm"];
_ist params ["_su", "_sv"];
private _ilenUV = (_ilenCm * (missionNamespace getVariable ["ACME_thora_pxPerCm", 60])) / 2048;
private _midU = _su + ((cos _iang) * (_ilenUV / 2));
private _midV = _sv + ((sin _iang) * (_ilenUV / 2));
private _cxUI = _bx + (_midU * _bw);
private _cyUI = _by + (_midV * _bh);
private _af = uiNamespace getVariable ["ACME_Thora_AspectFix", 0.5625];

private _offA = missionNamespace getVariable ["ACME_thora_holeFrameOffset", -90];
private _sgn = missionNamespace getVariable ["ACME_thora_holeFrameSign", 1];
private _ang = (((((_iang * _sgn) + _offA) mod 180) + 180) mod 180);
private _fr = (round (_ang / 15)) mod 12;
private _fs = if (_fr < 10) then { format ["0%1", _fr] } else { str _fr };

// the pleura bed, for split, kelly and finger.
if (!isNull _pleuraCtrl) then {
    if ((missionNamespace getVariable ["ACME_thora_usePleura", true]) && {_state in ["split", "kelly", "finger"]}) then {
        private _hP = (_ilenUV * (missionNamespace getVariable ["ACME_thora_pleuraScale", 1.6])) * _bh;
        private _wP = _hP * _af;
        _pleuraCtrl ctrlSetText format ["\acm_extended\ui\thora_pleura_%1_ca.paa", _fs];
        _pleuraCtrl ctrlSetPosition [_cxUI - (_wP / 2), _cyUI - (_hP / 2), _wP, _hP];
        _pleuraCtrl ctrlSetTextColor [1, 1, 1, 1];
        _pleuraCtrl ctrlShow true;
        _pleuraCtrl ctrlCommit 0;
    } else {
        _pleuraCtrl ctrlShow false;
    };
};

// the dark hole inside the pleura, for kelly and finger.
if (!isNull _openCtrl) then {
    if (_state in ["kelly", "finger"]) then {
        private _finger = _state == "finger";
        private _wide = _finger && {missionNamespace getVariable ["ACME_thora_useWideFinger", false]};
        private _prefix = if (_wide) then { "thora_hole_wide_" } else { "thora_hole_" };
        private _hH = (_ilenUV * (if (_finger) then { 0.8 } else { 0.72 })) * _bh;
        private _wH = _hH * _af;
        _openCtrl ctrlSetText format ["\acm_extended\ui\%1%2_ca.paa", _prefix, _fs];
        _openCtrl ctrlSetPosition [_cxUI - (_wH / 2), _cyUI - (_hH / 2), _wH, _hH];
        _openCtrl ctrlSetTextColor [1, 1, 1, 1];
        _openCtrl ctrlShow true;
        _openCtrl ctrlCommit 0;
    } else {
        _openCtrl ctrlShow false;
    };
};
