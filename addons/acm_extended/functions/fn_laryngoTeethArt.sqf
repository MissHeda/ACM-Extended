/* Persistent anatomy is never hidden by an instrument or a failed attempt. */
params ["_dlg"];
if (isNull _dlg) exitWith {};
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
private _broken = !isNull _patient && {(_patient getVariable ["ACME_laryngo_teethBroken", 0]) > 0};
uiNamespace setVariable ["ACME_laryngo_teethBroken", _broken];
{
    private _c = _dlg displayCtrl _x;
    _c ctrlShow true;
    _c ctrlSetFade 0;
    _c ctrlCommit 0;
    _c ctrlSetTextColor [1, 1, 1, 1];
} forEach [87803,87804,87805,87806,87808];
{
    private _c = _dlg displayCtrl _x;
    _c ctrlShow true;
    _c ctrlSetFade 0;
    _c ctrlCommit 0;
} forEach [87807,87878];
// The supplied fractured-teeth texture is rotated 180 degrees relative to sh_teeth.
// Rotate about the center of the common square canvas, preserving alignment and all original pixels.
(_dlg displayCtrl 87878) ctrlSetAngle [180, 0.5, 0.5, false];
(_dlg displayCtrl 87807) ctrlSetTextColor [1, 1, 1, ([1, 0] select _broken)];
(_dlg displayCtrl 87878) ctrlSetTextColor [1, 1, 1, ([0, 1] select _broken)];
