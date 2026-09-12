// the facing gate. if the device is turned round, nothing on the screen is visible, whatever any other code just
// decided.
// it is called as the last act of every frame and from inside each of the early-exit branches of the tick, because
// an exitwith skips the end of the function and those branches are exactly the ones that show things: the power-off
// substrate, the shutdown animation and the boot splash.
disableSerialization;
if !(uiNamespace getVariable ["ACME_vent_flipped", false]) exitWith {};
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};
[] call ACME_fnc_ventPanelHideScreen;
{ private _c = _dlg displayCtrl _x; if (!isNull _c) then { _c ctrlShow false; }; } forEach [87702, 87710, 87713, 87716, 87760];
{ if (!isNull _x) then { _x ctrlShow false; }; } forEach (uiNamespace getVariable ["ACME_vent_veilCtls", []]);
