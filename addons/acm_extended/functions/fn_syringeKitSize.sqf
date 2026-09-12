// the size list selection. it picks the barrel size, 1, 3, 5 or 10 ml, and resets the syringe to empty, ready for a
// source to be loaded.
// _this, from onLBSelChanged, is [_ctrl, _index].
params ["_ctrl", "_index"];
// ignore selection events fired by our own programmatic lbSetCurSel during the dialog setup. otherwise this reset
// would clobber the auto-loaded saline, taking the vol back to 0, on the frame the deferred event lands.
if (uiNamespace getVariable ["ACME_SK_Suppress", false]) exitWith {};
private _size = _ctrl lbValue _index;
if (_size <= 0) exitWith {};

uiNamespace setVariable ["ACME_SK_Size", _size];
uiNamespace setVariable ["ACME_SK_Vol", 0];
uiNamespace setVariable ["ACME_SK_SalineBase", -1];
uiNamespace setVariable ["ACME_SK_EpiMl", 0];
uiNamespace setVariable ["ACME_SK_Source", ""];
uiNamespace setVariable ["ACME_SK_Grab", false];

// clear the source-list selection, so the next source pick re-triggers.
private _display = uiNamespace getVariable ["ACME_SK_DLG", displayNull];
if (!isNull _display) then { (_display displayCtrl 86318) lbSetCurSel -1; };

[format ["%1 mL syringe. Pick a source on the left.", _size]] call ACME_fnc_syringeKitInfo;
call ACME_fnc_syringeKitRender;
