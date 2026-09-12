// move the megacode laptop to its spawn position plus an x, y and z offset expressed in the own heading frame of the
// laptop, where x is right, y is forward, the screen direction, and z is up, so the sliders read intuitively
// relative to how the laptop faces.
// it runs where the laptop is local. the laptop-side rope helper is attached to the laptop, so the cable follows
// automatically, and the caller rebuilds the rope length afterwards.
// _this is [_laptop, _x, _y, _z].
params ["_laptop", ["_x", 0], ["_y", 0], ["_z", 0]];
if (isNull _laptop) exitWith {};

private _base = _laptop getVariable ["ACME_MC_laptopBasePos", getPosATL _laptop];
private _dir  = (_laptop getVariable ["ACME_MC_laptopBaseDir", getDir _laptop]) * (pi / 180);
private _fwd   = [sin _dir, cos _dir, 0];
private _right = [cos _dir, -(sin _dir), 0];

private _pos = _base
    vectorAdd (_right vectorMultiply _x)
    vectorAdd (_fwd   vectorMultiply _y)
    vectorAdd [0, 0, _z];

_laptop setPosATL _pos;
