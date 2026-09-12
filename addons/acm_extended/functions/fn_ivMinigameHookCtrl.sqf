// give a control created at runtime the same wheel and middle button handlers the static controls got at init.
// call it as [_ctrl] call ACME_fnc_ivMinigameHookCtrl.
// a control under the pointer swallows the mouse event, so any sprite the medic can end up hovering has to carry
// these or the wheel and the middle button do nothing while the cursor is over it. the catheter sprite is the
// worst case, because the pointer is pinned to it for the whole insertion.
params ["_ctrl"];
if (isNull _ctrl) exitWith {};
private _mb = uiNamespace getVariable ["ACME_IV_MBHandler", {}];
private _mbUp = uiNamespace getVariable ["ACME_IV_MBUpHandler", {}];
private _sc = uiNamespace getVariable ["ACME_IV_ScrollHandler", {}];
if (!(_mb isEqualTo {})) then { _ctrl ctrlAddEventHandler ["MouseButtonDown", _mb]; };
if (!(_mbUp isEqualTo {})) then { _ctrl ctrlAddEventHandler ["MouseButtonUp", _mbUp]; };
if (!(_sc isEqualTo {})) then { _ctrl ctrlAddEventHandler ["MouseZChanged", _sc]; };
