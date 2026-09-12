// give the held needle its weight, and return where the point of it actually is.
// call it as [_ux, _uy, _dt] call ACME_fnc_ivNeedleTip, which returns [_x, _y] in the same units.
//
// the float.
// this is the first of the two springs the ET tube uses, and only the first. the tip lags the cursor by a short
// exponential, so the needle reads as an object held in the hand rather than a sprite welded to the pointer.
// the second spring, the swing about the held point, is deliberately absent. a tube is long and flexible and it
// bends. a catheter is 30 to 45 mm of rigid steel and it does not, so a needle that swung would be wrong.
//
// the tremor.
// a hand holding a needle is never still, and the hand of a medic who has been running is less still again.
// the tremor is the sum of a slow drift and a fast component, which is what a real tremor looks like, and it is
// scaled by the fatigue and the heart rate of the medic.
// it is meant to be barely visible. it is enough to make a small target harder to hit while sprinting, and not
// enough to be noticed on a rested medic.
params ["_ux", "_uy", ["_dt", 0.02]];
if (_dt <= 0) then { _dt = 0.02 };

// the lag. the same integration form the tube uses, so one long frame does not overshoot.
private _tp = uiNamespace getVariable ["ACME_IV_NeedleTipPos", []];
if (count _tp < 2) then { _tp = [_ux, _uy]; };
_tp params ["_px", "_py"];
private _f = 1 - (exp (-((missionNamespace getVariable ["ACME_iv_needleLag", 22]) * _dt)));
private _nx = _px + ((_ux - _px) * _f);
private _ny = _py + ((_uy - _py) * _f);
uiNamespace setVariable ["ACME_IV_NeedleTipPos", [_nx, _ny]];

// the tremor scale.
// fatigue runs 0 to 1. the heart rate of the medic is counted only above rest, so a calm medic contributes
// nothing through it and a medic who has just sprinted contributes most of the tremor.
// ACE advanced fatigue publishes ace_advanced_fatigue_aimFatigue, 0 to 1, and it is the one to read. with
// advanced fatigue enabled the engine getFatigue returns nothing useful, because ACE takes the engine stamina
// out and runs its own model. the engine value is the fallback for a mission with advanced fatigue turned off.
// this was checked in the ACE source rather than assumed. a wrong name here would read as no tremor at all.
private _fat = 0;
if (!isNull ACE_player) then {
    _fat = ACE_player getVariable ["ace_advanced_fatigue_aimFatigue", -1];
    if (!(_fat isEqualType 0) || {_fat < 0}) then { _fat = getFatigue ACE_player; };
    _fat = _fat max 0 min 1;
};
private _hr = 80;
if (!isNull ACE_player) then { _hr = ACE_player getVariable ["ace_medical_heartRate", 80]; };
private _hrTerm = (linearConversion [
    (missionNamespace getVariable ["ACME_iv_tremorHRFloor", 75]),
    (missionNamespace getVariable ["ACME_iv_tremorHRCeil", 150]),
    _hr, 0, 1, true]);

private _base = missionNamespace getVariable ["ACME_iv_tremorBase", 0.0006];
private _amp = _base * ((missionNamespace getVariable ["ACME_iv_tremorFloor", 0.25])
    + (0.9 * _fat) + (0.9 * _hrTerm));

// two components. the slow one wanders, the fast one buzzes, and the pair does not read as a repeating pattern.
private _t = CBA_missionTime;
private _slow = missionNamespace getVariable ["ACME_iv_tremorSlowHz", 1.7];
private _fast = missionNamespace getVariable ["ACME_iv_tremorFastHz", 9];
private _ox = _amp * ((sin ((_t * _slow) * 360)) + (0.45 * (sin ((_t * _fast) * 360))));
private _oy = _amp * ((cos ((_t * _slow * 0.83) * 360)) + (0.45 * (cos ((_t * _fast * 1.13) * 360))));

// the vertical unit is a smaller fraction of the screen than the horizontal one, so the vertical part is scaled
// to keep the tremor round rather than tall.
private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
if (_af > 0) then { _oy = _oy * _af; };

[_nx + _ox, _ny + _oy]
