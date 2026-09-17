// toggle grabbing the plunger during flush/compound draw flow.
// The cursor is never warped. Once grabbed, the next left click anywhere in the dialog releases the plunger so a
// moved hitbox cannot strand the provider in drag mode.
private _stage = uiNamespace getVariable ["ACME_SK_WasteStage", ""];
if (_stage == "") exitWith {};

disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};

// A display-level release click sets this briefly so the same physical click's control MouseButtonUp cannot re-grab.
private _suppressUntil = uiNamespace getVariable ["ACME_SK_PlungerSuppressUpUntil", -1];
if (_suppressUntil isEqualType 0 && {diag_tickTime <= _suppressUntil}) exitWith {
    uiNamespace setVariable ["ACME_SK_PlungerSuppressUpUntil", -1];
};

private _moving = !(uiNamespace getVariable ["ACME_SK_WasteMoving", false]);
uiNamespace setVariable ["ACME_SK_WasteMoving", _moving];

private _oldRelease = _dlg getVariable ["ACME_SK_PlungerReleaseEH", -1];
if (_oldRelease isEqualType 0 && {_oldRelease >= 0}) then {
    _dlg displayRemoveEventHandler ["MouseButtonDown", _oldRelease];
    _dlg setVariable ["ACME_SK_PlungerReleaseEH", -1];
};

if (_moving) then {
    private _eh = _dlg displayAddEventHandler ["MouseButtonDown", {
        params ["_display", "_button"];
        if (_button != 0 || {!(uiNamespace getVariable ["ACME_SK_WasteMoving", false])}) exitWith {false};
        uiNamespace setVariable ["ACME_SK_WasteMoving", false];
        uiNamespace setVariable ["ACME_SK_PlungerSuppressUpUntil", diag_tickTime + 0.20];
        private _pl = _display displayCtrl 84009;
        if (!isNull _pl) then {_pl ctrlSetTooltip "Click to grab the plunger";};
        private _id = _display getVariable ["ACME_SK_PlungerReleaseEH", -1];
        if (_id isEqualType 0 && {_id >= 0}) then {
            _display displayRemoveEventHandler ["MouseButtonDown", _id];
            _display setVariable ["ACME_SK_PlungerReleaseEH", -1];
        };
        true
    }];
    _dlg setVariable ["ACME_SK_PlungerReleaseEH", _eh];
};

private _plunger = _dlg displayCtrl 84009;
if (!isNull _plunger) then {
    _plunger ctrlSetTooltip (["Click to grab the plunger", "Click anywhere to release the plunger"] select _moving);
};
