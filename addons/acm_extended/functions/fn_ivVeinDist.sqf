// the distance from a body-fraction point, [_fx,_fy], to the vein.
// the vein is a thin vertical strip rather than a point: anatomically it runs along the limb, so it is pinpoint-tight
// horizontally and has a palpable length of about half an inch to an inch that you can feel and stick anywhere
// along.
// it returns the isotropic distance in body-width fractions, where 0 is dead on the vein. inside the strip the
// distance is purely horizontal, so the whole length reads the same.
// call it as [_fx, _fy] call ACME_fnc_ivVeinDist, which returns _dist.
params ["_fx", "_fy"];
(uiNamespace getVariable ["ACME_IV_VeinUV", [0.5, 0.5]]) params ["_vu", "_vv"];
private _af   = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
private _half = uiNamespace getVariable ["ACME_IV_StripHalf", 0.045];
private _top  = _vv - _half;
private _bot  = _vv + _half;
private _nearVy = (_fy max _top) min _bot;  // nearest point along the strip (same x = _vu)
private _dx = _fx - _vu;
private _dy = (_fy - _nearVy) * (1 / _af);  // 0 inside the strip; else vertical overshoot past an end
sqrt ((_dx * _dx) + (_dy * _dy))
