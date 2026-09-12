// move the wheel picture to a clamp position, where 0 is top and closed and 1 is bottom and open.
// important: the shipped paa textures are 2048 by 2048 canvases with the art padded in unscaled, because a paa
// requires power-of-two. the *content vars describe where the art sits inside its canvas, as [x, y, w, h], and all
// the sizing below is done on the art rather than the control, so the padding is fully compensated.
params [["_position", 0.5]];

private _display = findDisplay 86200;
if (isNull _display) exitWith {false};

private _ctrlWheel = _display displayCtrl 86202;
if (isNull _ctrlWheel) exitWith {false};

// the track is the clamp art rect in screen coords, set by onClampLoad.
private _track = uiNamespace getVariable ["ACME_RollerClamp_Track", []];
if (_track isEqualTo []) exitWith {false};
_track params ["_x", "_y", "_w", "_h"];

private _top = missionNamespace getVariable ["ACME_infusion_clampTravelTop", 0.186];
private _bottom = missionNamespace getVariable ["ACME_infusion_clampTravelBottom", 0.849];
private _xRatio = missionNamespace getVariable ["ACME_infusion_clampWheelXRatio", 0.49];
private _heightRatio = missionNamespace getVariable ["ACME_infusion_clampWheelHeightRatio", 0.247];
private _content = missionNamespace getVariable ["ACME_infusion_clampWheelContent", [0.4336, 0.7120, 0.1328, 0.2720]];
_content params ["_cX", "_cY", "_cW", "_cH"];

private _rel = (_position max 0) min 1;
private _targetX = _x + (_w * _xRatio);
// flipped: the position is openness, where 0 is closed and 1 is open, and the wheel rides up to open now. so an
// openness of 1 maps to the top of the travel band and 0 to the bottom, which is the real roller-clamp feel, where
// rolling up opens.
private _targetY = _y + (_h * (_top + ((_bottom - _top) * (1 - _rel))));

// the wheel art size, aspect-true, because the art is 272 by 557 px.
private _unitFix = pixelW / pixelH;  // exact at any resolution/aspect/stretch mode
private _artH = _h * _heightRatio;
private _artW = _artH * (272 / 557) * _unitFix;

// scale the control up so the art inside it comes out at the desired size, then offset so the center of the art
// lands on the target point.
private _ctrlW = _artW / (_cW max 0.01);
private _ctrlH = _artH / (_cH max 0.01);
private _ctrlX = _targetX - (_ctrlW * (_cX + (_cW / 2)));
private _ctrlY = _targetY - (_ctrlH * (_cY + (_cH / 2)));

_ctrlWheel ctrlSetPosition [_ctrlX, _ctrlY, _ctrlW, _ctrlH];
_ctrlWheel ctrlCommit 0;

if !(uiNamespace getVariable ["ACME_RollerClamp_LoggedWheel", false]) then {
    uiNamespace setVariable ["ACME_RollerClamp_LoggedWheel", true];
};
true
