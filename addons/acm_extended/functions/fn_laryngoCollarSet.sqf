// fastening the collar.
// call it as [] call ACME_fnc_laryngoCollarSet.
// the loose collar, ett_secured_f1, is replaced by the fastened one, ett_secured_f2, pinned at its measured resting
// place, and the tube is now mechanically secured. all that is left after this is the cuff.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_laryngo_state", ""]) != "collar") exitWith {};

(uiNamespace getVariable ["ACME_laryngo_frame", [0,0,0.2,0.2]]) params ["_fx", "_fy", "_fw", "_fh"];
(missionNamespace getVariable ["ACME_laryngo_collarUV", [0.4991, 0.4925]]) params ["_coU", "_coV"];
(missionNamespace getVariable ["ACME_laryngo_collarTarget", [0.4991, 0.3558]]) params ["_ctU", "_ctV"];

(_dlg displayCtrl 87909) ctrlSetTextColor [1,1,1,0];
private _c = _dlg displayCtrl 87910;
_c ctrlSetPosition [_fx + ((_ctU - _coU) * _fw), _fy + ((_ctV - _coV) * _fh), _fw, _fh];
_c ctrlCommit 0;
_c ctrlSetTextColor [1,1,1,1];

// used. it is on the tube now, so it leaves the hand and comes off the tray count.
uiNamespace setVariable ["ACME_laryngo_held", ""];
uiNamespace setVariable ["ACME_laryngo_collarUsed", true];
uiNamespace setVariable ["ACME_laryngo_state", "complete"];
playSound "ACME_VentClick";
// secured. from here the tube is fixed and the screen will not let it be disturbed.
private _pat = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (!isNull _pat) then { [_pat, -1, -1, true, false, true, false] call ACME_fnc_ettAirwayStateCommit; };
(_dlg displayCtrl 87816) ctrlSetText "";
[] call ACME_fnc_laryngoRefreshSlots;
