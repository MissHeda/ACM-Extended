// orient a megacode laptop from its base heading plus pitch, yaw and roll offsets, in degrees. it composes the
// rotation as yaw, about world z, then pitch, about the right axis of the laptop, then roll, about its forward
// axis, and applies it with setVectorDirAndUp. it runs where the laptop is local.
// _this is [_laptop, _pitch, _yaw, _roll].
params ["_laptop", ["_pitch", 0], ["_yaw", 0], ["_roll", 0]];
if (isNull _laptop) exitWith {};

private _base = _laptop getVariable ["ACME_MC_laptopBaseDir", getDir _laptop];
private _y = (_base + _yaw) * (pi / 180);
private _p = _pitch * (pi / 180);
private _r = _roll  * (pi / 180);

// yaw about world z.
private _fwd   = [sin _y, cos _y, 0];
private _right = [cos _y, -(sin _y), 0];
private _up    = [0, 0, 1];

// pitch about the right axis, meaning nose up and down.
private _fwd2 = (_fwd vectorMultiply (cos _p)) vectorAdd (_up  vectorMultiply (sin _p));
private _up2  = (_up  vectorMultiply (cos _p)) vectorAdd (_fwd vectorMultiply (-(sin _p)));

// roll about the new forward axis, tilting up toward the right.
private _up3 = (_up2 vectorMultiply (cos _r)) vectorAdd (_right vectorMultiply (sin _r));

_laptop setVectorDirAndUp [_fwd2, _up3];
