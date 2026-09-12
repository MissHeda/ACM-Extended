// change the catheter sprite to a new frame with a short crossfade.
// call it as [_ctrl, _texture] call ACME_fnc_ivCathSetFrame.
// swapping ctrlSetText cuts from one frame to the next on a single frame boundary, which reads as a stutter when
// the frames are close together. the needle appears to jump rather than advance.
// this holds the outgoing frame on a second control at the same position and fades it out while the new one fades
// in. ctrlCommit animates the color change, so the blend costs nothing per frame.
// the ghost is created once and reused. it is deleted with the rest of the sprites in fn_ivminigameclose.
params ["_ctrl", "_tex"];
if (isNull _ctrl) exitWith {};
if (_tex isEqualTo "") exitWith {};
private _shown = ctrlText _ctrl;
private _variant = _ctrl getVariable ["ACME_NV_Variant", ""];
private _source = if (_variant != "" && {_shown == _variant}) then {_ctrl getVariable ["ACME_NV_BaseTexture", _shown]} else {_shown};
// Compare logical frames. A derived NV picture must not restart the crossfade every tick.
if (_source isEqualTo _tex) exitWith {};

private _dur = missionNamespace getVariable ["ACME_iv_frameFade", 0.10];
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg || {_dur <= 0}) exitWith {
    _ctrl ctrlSetText _tex;
    _ctrl ctrlCommit 0;
};

private _pos = ctrlPosition _ctrl;
private _old = _source;

private _ghost = uiNamespace getVariable ["ACME_IV_CathGhost", controlNull];
if (isNull _ghost) then {
    _ghost = _dlg ctrlCreate ["ACME_IV_Catheter", -1];
    uiNamespace setVariable ["ACME_IV_CathGhost", _ghost];
    if (!isNil "ACME_fnc_ivMinigameHookCtrl") then { [_ghost] call ACME_fnc_ivMinigameHookCtrl; };
};

// the outgoing frame, held where it was and faded out.
if (_old isNotEqualTo "") then {
    _ghost ctrlSetText _old;
    _ghost ctrlSetPosition _pos;
    (_ctrl getVariable ["ACME_IV_Pose", [0,0.5,0.5]]) params ["_angle", "_u", "_v"];
    _ghost ctrlSetAngle [_angle, _u, _v, false];
    _ghost ctrlSetTextColor [1, 1, 1, 1];
    _ghost ctrlCommit 0;
    _ghost ctrlShow true;
    _ghost ctrlSetTextColor [1, 1, 1, 0];
    _ghost ctrlCommit _dur;
};

// the incoming frame, faded in underneath it.
_ctrl ctrlSetText _tex;
_ctrl ctrlSetTextColor [1, 1, 1, 0];
_ctrl ctrlCommit 0;
_ctrl ctrlSetTextColor [1, 1, 1, 1];
_ctrl ctrlCommit _dur;
