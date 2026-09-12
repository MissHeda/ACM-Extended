// resolve the cursor in the ui coordinate space of the iv dialog, in three tiers and ultrawide-safe. it is shared by
// the tick and the click router, and returns [ux, uy] or [].
private _finite = { params ["_v"]; (_v isEqualType 0) && {finite _v} };
private _now = diag_tickTime;

private _evt  = uiNamespace getVariable ["ACME_IV_EvtUI", []];
private _evtT = uiNamespace getVariable ["ACME_IV_EvtUITime", -1];
if ((_evt isEqualType []) && {count _evt == 2} && {[_evtT] call _finite} && {(_now - _evtT) < 0.05}) exitWith { _evt };

private _gmp = getMousePosition; _gmp params ["_gx", "_gy"];
if !(([_gx] call _finite) && {[_gy] call _finite}) exitWith { [] };

private _xMinG = uiNamespace getVariable ["ACME_IV_CalXminG",  1e9];
private _xMaxG = uiNamespace getVariable ["ACME_IV_CalXmaxG", -1e9];
private _yMinG = uiNamespace getVariable ["ACME_IV_CalYminG",  1e9];
private _yMaxG = uiNamespace getVariable ["ACME_IV_CalYmaxG", -1e9];
if (((_xMaxG - _xMinG) > 0.02) && {(_yMaxG - _yMinG) > 0.02}) exitWith {
    private _xMinU = uiNamespace getVariable ["ACME_IV_CalXminU", 0];
    private _xMaxU = uiNamespace getVariable ["ACME_IV_CalXmaxU", 0];
    private _yMinU = uiNamespace getVariable ["ACME_IV_CalYminU", 0];
    private _yMaxU = uiNamespace getVariable ["ACME_IV_CalYmaxU", 0];
    private _sx = (_xMaxU - _xMinU) / (_xMaxG - _xMinG);
    private _sy = (_yMaxU - _yMinU) / (_yMaxG - _yMinG);
    [(_xMinU - (_sx * _xMinG)) + (_sx * _gx), (_yMinU - (_sy * _yMinG)) + (_sy * _gy)]
};

[safeZoneXAbs + (_gx * safeZoneWAbs), safeZoneY + (_gy * safeZoneH)]
