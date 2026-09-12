// the cursor position in the ui coordinate space of the chest-seal dialog, robust to the display mode.
// the problem: under ultrawide non-stretch the cursor lives in full-screen space while the 2d ui is scaled into a
// central region. getMousePosition returns 0 to 1 and no fixed safezone formula, safe, abs or raw, maps it to
// where the controls actually render. that mismatch is the tiny-move-into-huge-sweep amplification that threw the
// fingertips off the body.
// the fix has three tiers.
// 1. fresh engine ui coords from the MouseMoving and MouseHolding of the interaction surface. this is
// display-mode independent, because the engine reports exactly where the cursor is in control space.
// 2. if those are a frame stale, such as during a fast drag, map getMousePosition through a linear transform the
// surface auto-calibrates at runtime from those same getMousePosition and engineui pairs.
// 3. before the calibration exists, use a plain absolute-safezone map as a seed.
// the extra params are kept for caller compatibility and are ignored.
params [["_preferredRect", []], ["_recalibrate", false], ["_truePoint", []]];

private _finite = {
    params ["_v"];
    (_v isEqualType 0) && {finite _v}
};

private _now = diag_tickTime;

// 1. fresh engine ui coords.
private _evt  = uiNamespace getVariable ["ACME_CS_EvtUI", []];
private _evtT = uiNamespace getVariable ["ACME_CS_EvtUITime", -1];
private _evtFresh = (_evt isEqualType []) && {count _evt == 2} && {[_evtT] call _finite} && {(_now - _evtT) < 0.05};
if (_evtFresh) then {
    _evt params ["_ex0", "_ey0"];
    _evtFresh = ([_ex0] call _finite) && {[_ey0] call _finite};
};
if (_evtFresh) exitWith {
    uiNamespace setVariable ["ACME_CS_CoordSrc", "EVT"];
    _evt
};

// getMousePosition, needed for tiers 2 and 3.
private _gmp = getMousePosition;
_gmp params ["_gx", "_gy"];
private _gmpOk = ([_gx] call _finite) && {[_gy] call _finite};

// 2. calibrated getMousePosition into ui.
private _xMinG = uiNamespace getVariable ["ACME_CS_CalXminG",  1e9];
private _xMaxG = uiNamespace getVariable ["ACME_CS_CalXmaxG", -1e9];
private _yMinG = uiNamespace getVariable ["ACME_CS_CalYminG",  1e9];
private _yMaxG = uiNamespace getVariable ["ACME_CS_CalYmaxG", -1e9];
private _calOk = _gmpOk
    && {[_xMinG] call _finite} && {[_xMaxG] call _finite} && {[_yMinG] call _finite} && {[_yMaxG] call _finite}
    && {(_xMaxG - _xMinG) > 0.02} && {(_yMaxG - _yMinG) > 0.02};
if (_calOk) exitWith {
    private _xMinU = uiNamespace getVariable ["ACME_CS_CalXminU", 0];
    private _xMaxU = uiNamespace getVariable ["ACME_CS_CalXmaxU", 0];
    private _yMinU = uiNamespace getVariable ["ACME_CS_CalYminU", 0];
    private _yMaxU = uiNamespace getVariable ["ACME_CS_CalYmaxU", 0];
    private _slopeX = (_xMaxU - _xMinU) / (_xMaxG - _xMinG);
    private _slopeY = (_yMaxU - _yMinU) / (_yMaxG - _yMinG);
    private _ux = (_xMinU - (_slopeX * _xMinG)) + (_slopeX * _gx);
    private _uy = (_yMinU - (_slopeY * _yMinG)) + (_slopeY * _gy);
    private _res = _gmp;
    if (([_ux] call _finite) && {[_uy] call _finite}) then {
        uiNamespace setVariable ["ACME_CS_CoordSrc", "CAL"];
        _res = [_ux, _uy];
    } else {
        uiNamespace setVariable ["ACME_CS_CoordSrc", "CAL!"];
    };
    _res
};

// 3. the pre-calibration seed: an absolute-safezone map.
if (!_gmpOk) exitWith {
    uiNamespace setVariable ["ACME_CS_CoordSrc", "none"];
    []
};
private _axx = safeZoneXAbs;
private _ayy = safeZoneY;
private _aww = safeZoneWAbs;
private _ahh = safeZoneH;
if !(([_axx] call _finite) && {[_ayy] call _finite} && {[_aww] call _finite} && {[_ahh] call _finite} && {_aww > 0} && {_ahh > 0}) exitWith {
    uiNamespace setVariable ["ACME_CS_CoordSrc", "raw"];
    _gmp
};
uiNamespace setVariable ["ACME_CS_CoordSrc", "ABS"];
[_axx + (_gx * _aww), _ayy + (_gy * _ahh)]
