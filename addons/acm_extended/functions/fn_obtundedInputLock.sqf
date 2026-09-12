// B49: obtundation no longer blocks locomotion or stance input. This function now only removes input handlers that
// may have been installed by an older hot-loaded build, so entering obtundation can never strand the player in the
// former forced-prone/forced-supine control scheme.
params [["_patient", objNull], ["_enable", false]];
if (!hasInterface) exitWith {};
private _display = uiNamespace getVariable ["ACME_ObtundedInputDisplay", displayNull];
private _keyEH = uiNamespace getVariable ["ACME_ObtundedInputKeyEH", -1];
private _mouseEH = uiNamespace getVariable ["ACME_ObtundedInputMouseDownEH", -1];
if (!isNull _display) then {
    if (_keyEH >= 0) then {_display displayRemoveEventHandler ["KeyDown", _keyEH];};
    if (_mouseEH >= 0) then {_display displayRemoveEventHandler ["MouseButtonDown", _mouseEH];};
};
uiNamespace setVariable ["ACME_ObtundedInputDisplay", displayNull];
uiNamespace setVariable ["ACME_ObtundedInputKeyEH", -1];
uiNamespace setVariable ["ACME_ObtundedInputMouseDownEH", -1];
uiNamespace setVariable ["ACME_ObtundedInputLocked", false];
uiNamespace setVariable ["ACME_ObtundedBlockedKeys", []];
uiNamespace setVariable ["ACME_ObtundedBlockedMouseButtons", []];
uiNamespace setVariable ["ACME_ObtundedBlockedComboKeys", []];
uiNamespace setVariable ["ACME_ObtundedBlockedKeysProne", []];
uiNamespace setVariable ["ACME_ObtundedBlockedMouseButtonsProne", []];
uiNamespace setVariable ["ACME_ObtundedBlockedComboKeysProne", []];
if (!isNull ACE_player) then {
    ACE_player setVariable ["ACME_obtunded_weaponTransition", false, false];
    ACE_player setVariable ["ACME_obtunded_pendingWeapon", "", false];
};
