// advance the insertion while the medic holds lmb and pushes.
// call it from the tick as [_drag] call ACME_fnc_ivMinigameInsertAdvance.
// it reads the raw mouse rather than the dialog cursor, then puts the mouse back where it started, every frame.
// that pins the pointer to the needle tip, so the push can run as long as the catheter is deep, and the pointer
// never reaches the edge of the screen and stops.
// the needle only goes in along its own axis. pushing sideways does nothing, which is the point.
params [["_drag", false]];
if ((uiNamespace getVariable ["ACME_IV_InsStage", ""]) != "advance") exitWith {};
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", []];
if (_rect isEqualTo []) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];

// let go and the needle stays where it is, because it is in the arm.
if (!_drag) exitWith {};

private _pin = uiNamespace getVariable ["ACME_IV_InsPin", []];
if !(_pin isEqualType [] && {count _pin >= 2}) exitWith {
    uiNamespace setVariable ["ACME_IV_InsPin", getMousePosition];
};
_pin params ["_px", "_py"];
private _m = getMousePosition;
_m params ["_mx", "_my"];

// the raw mouse is a screen fraction. convert the travel into the ui units the body rect is measured in.
private _dux = (_mx - _px) * safeZoneWAbs;
private _duy = (_my - _py) * safeZoneH;

private _suffix = uiNamespace getVariable ["ACME_IV_InsSuffix", ""];
private _geometry = [_suffix, uiNamespace getVariable ["ACME_IV_InsAngle", 0]] call ACME_fnc_ivCathGeometry;
(_geometry select 3) params ["_sx", "_sy"];
private _len = sqrt (_sx * _sx + _sy * _sy);
if (_len <= 0) exitWith {};
_sx = _sx / _len;
_sy = _sy / _len;
// Express both mouse axes in vertical-pixel UI units before taking the dot product.
private _aspect = pixelW / (pixelH max 1e-9);
_dux = _dux / _aspect;

// project the push onto the needle. pulling back subtracts, so a wrong push can be walked off.
private _proj = ((_dux * _sx) + (_duy * _sy));

// the travel that buries the assembly fully, in ui units. it follows the sprite scale, so a smaller catheter
// takes a proportionally shorter push and the movement still looks one to one.
// tune it with ACME_iv_cathTravel, in body heights. larger is a longer push.
private _cs = uiNamespace getVariable ["ACME_IV_CathScale", 0.62];
private _full = (missionNamespace getVariable ["ACME_iv_cathTravel", 0.085]) * _bh * _cs;
if (_full <= 0) exitWith {};
private _prog = ((uiNamespace getVariable ["ACME_IV_InsProg", 0]) + (_proj / _full)) max 0 min 1;
uiNamespace setVariable ["ACME_IV_InsProg", _prog];

// put the pointer back on the tip. this is what makes the push unbounded.
setMousePosition [_px, _py];

// the catheter goes all the way in whether or not it found the vein. the needle is in the skin either way, and
// stopping the push short was the game telling the medic they had missed before they could see it.
// the flashback frames still play, because there is only one set of art. what the medic does not get is a line
// that works: a stick that missed seats the hub and then infiltrates, handled at the commit.
private _f = 1 + round (_prog * 5);
if (_f != (uiNamespace getVariable ["ACME_IV_InsFrame", 1])) then {
    uiNamespace setVariable ["ACME_IV_InsFrame", _f];
    private _cath = uiNamespace getVariable ["ACME_IV_CathCtrl", controlNull];
    if (!isNull _cath) then {
        [_cath, ([(uiNamespace getVariable ["ACME_IV_InsGauge", 16]), _suffix, _f] call ACME_fnc_ivCathTex)] call ACME_fnc_ivCathSetFrame;
    };
};

// fully in, and in the vein. the catheter can now be threaded off the needle.
if (_f >= 6) then {
    uiNamespace setVariable ["ACME_IV_InsStage", "thread"];
    private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
    if (!isNull _dlg) then { (_dlg displayCtrl 86503) ctrlSetText "Scroll to thread the catheter off the needle."; };
    playSound "ACE_Sound_Click";
};
