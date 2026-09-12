/* Square-pixel catheter canvas and its physically rotated needle axis.
   [_frame, _angle, _scale, _anchorOverride] call ACME_fnc_ivCathGeometry
   Returns [width, height, anchorUV, axisXY]. axisXY is in screen-pixel space. */
params [["_frame", ""], ["_angle", 0], ["_scale", -1], ["_anchorOverride", []]];
if !(_angle isEqualType 0 && {finite _angle}) then {_angle = 0;};
if (_scale < 0) then {_scale = uiNamespace getVariable ["ACME_IV_CathScale", 0.62];};
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", [0,0,1,1]];
private _height = (_rect param [3, 1]) * _scale;
// These are UI units per physical pixel, not safe-zone width/height fractions.
// Equal physical dimensions are required before rotating a square PAA canvas.
private _aspect = pixelW / (pixelH max 1e-9);
private _width = _height * _aspect;
private _anchor = (uiNamespace getVariable ["ACME_IV_FrameAnchors", createHashMap]) getOrDefault [_frame, [0.49166,0.44434]];
if (count _anchorOverride >= 2) then {_anchor = _anchorOverride;};
private _axis = (uiNamespace getVariable ["ACME_IV_FrameAxis", createHashMap]) getOrDefault [_frame, [0,-1]];
_axis params ["_ax", "_ay"];
private _c = cos _angle;
private _s = sin _angle;
[_width, _height, _anchor, [_ax * _c - _ay * _s, _ax * _s + _ay * _c]]
