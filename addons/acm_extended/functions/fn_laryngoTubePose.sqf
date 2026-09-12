// placing the tube when it is being held by the tip.
// call it as [_dlg, _tipX, _tipY, _ang] call ACME_fnc_laryngoTubePose.
// all six stage layers are positioned so the distal tip lands exactly on the given point, then rotated about that
// same point by _ang degrees. pinning the rotation to the tip is what produces the pendulum: the tip is where
// your fingers are, and the length of the tube hangs off it and swings.
// it is held by the tip. the tube is a near-vertical band spanning v 0.275 to 0.709 of its own canvas, and the top
// pixels are the business end: that is what goes into the airway, and on the new frames it stays put at the top
// while the length behind it shortens. so the anchor is the very tip, at uv [0.5035, 0.2749], and everything else
// about the tube hangs off that point.
params ["_dlg", "_tipX", "_tipY", ["_ang", 0]];
if (isNull _dlg) exitWith {};

(missionNamespace getVariable ["ACME_laryngo_tubeTipUV", [0.5035, 0.2749]]) params ["_tu", "_tv"];
// the tube is an instrument, so it lives on the frame rect like the blade rather than on the offset head rect.
(uiNamespace getVariable ["ACME_laryngo_frame", uiNamespace getVariable ["ACME_laryngo_rect", [0,0,0.2,0.2]]]) params ["_rx", "_ry", "_rw", "_rh"];

private _ox = _tipX - (_tu * _rw);
private _depthB52 = uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0];
private _liftVB52 = missionNamespace getVariable ["ACME_laryngo_tubeVisualLiftV", 0.010];
private _oy = _tipY - (_tv * _rh) - ((_depthB52 max 0 min 1) * _liftVB52 * _rh);

// the swing needs control rotation. if it ever fails to render on this control type, set ACME_laryngo_tubeSwing to
// false: the tube stays tip-anchored and still has the weight from the tip spring, and it simply stops
// leaning.
private _swing = missionNamespace getVariable ["ACME_laryngo_tubeSwing", true];
{
    private _c = _dlg displayCtrl _x;
    _c ctrlSetPosition [_ox, _oy, _rw, _rh];
    if (_swing) then { _c ctrlSetAngle [_ang, _tu, _tv, false]; };
    _c ctrlCommit 0;
} forEach [87900, 87901, 87902, 87903, 87904, 87905, 87906, 87907, 87908];
