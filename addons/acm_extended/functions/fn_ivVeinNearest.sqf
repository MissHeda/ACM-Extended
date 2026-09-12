// the nearest palpable vein to a point, out of every candidate at this site.
// call it as [_fx, _fy] call ACME_fnc_ivVeinNearest, which returns [_dist, _u, _v, _quality, _name] for the
// nearest one, or [1e9, 0.5, 0.5, 1, ""] when there is no candidate set.
//
// this generalizes what the external jugular path in fn_ivMinigameTick has always done. the EJ holds two
// veins, measures the cursor against both and takes the nearer. the fossa now holds up to four and does the
// same thing through one function, so there is one nearest-vein rule rather than a special case per site.
//
// the distance rule is the one fn_ivVeinDist already used: a vein is a thin vertical strip, pinpoint tight
// across the limb and palpable along its length, so inside the strip the distance is purely horizontal and the
// whole run reads the same. the aspect fix keeps it isotropic, or a vein would be easier to find vertically
// than horizontally purely because of the screen.
params ["_fx", "_fy"];
private _set = uiNamespace getVariable ["ACME_IV_VeinSet", []];
if (_set isEqualTo []) exitWith { [1e9, 0.5, 0.5, 1, ""] };

private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
private _bestD = 1e9;
private _best = [];

{
    _x params ["_vu", "_vv", "_half", "_q", "_nm"];
    private _top = _vv - _half;
    private _bot = _vv + _half;
    private _nearVy = (_fy max _top) min _bot;
    private _dx = _fx - _vu;
    private _dy = (_fy - _nearVy) * (1 / _af);
    private _d = sqrt ((_dx * _dx) + (_dy * _dy));
    // a thready vein is a SMALLER target, not merely a dimmer one. dividing the measured distance by quality
    // makes a poor vein read as further away than it geometrically is, which shrinks both its green core and
    // its warm halo by the same factor and needs no second set of radii to maintain.
    private _eff = _d / ((_q max 0.05) min 2);
    if (_eff < _bestD) then { _bestD = _eff; _best = [_eff, _vu, _vv, _q, _nm]; };
} forEach _set;

if (_best isEqualTo []) exitWith { [1e9, 0.5, 0.5, 1, ""] };
_best
