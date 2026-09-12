/* Place an unwarped catheter/line and rotate about its actual insertion/connector point.
   Uses a plain picture on a square-pixel canvas: no aspect-fit resize during rotation.
   [_ctrl, _tipX, _tipY, _frame, _angle, _scale, _anchorOverride] call ACME_fnc_ivCathPose */
params ["_ctrl", "_tipX", "_tipY", ["_frame", ""], ["_angle", 0], ["_scale", -1], ["_anchorOverride", []]];
if (isNull _ctrl) exitWith {[]};
if !(_angle isEqualType 0 && {finite _angle}) then {_angle = 0;};
([_frame, _angle, _scale, _anchorOverride] call ACME_fnc_ivCathGeometry) params ["_w", "_h", "_anchor"];
_anchor params ["_u", "_v"];
private _pos = [_tipX - _w * _u, _tipY - _h * _v, _w, _h];
_ctrl ctrlSetPosition _pos;
_ctrl ctrlSetAngle [_angle, _u, _v, false];
_ctrl setVariable ["ACME_IV_Pose", [_angle, _u, _v]];
_ctrl ctrlCommit 0;
_pos
