// The seal leaves its black silhouette in the tray while in hand. The count says "IN HAND", and
// after you place it the slot reloads the next seal if you still have stock. the logo dims when you are out.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (isNull _display) exitWith {};
private _n    = uiNamespace getVariable ["ACME_CS_SealsLeft", 0];
private _held = uiNamespace getVariable ["ACME_CS_Held", false];
private _logo = _display displayCtrl 86422;
private _cnt  = _display displayCtrl 86423;
[_logo, _held, _n] call ACME_fnc_traySlotState;
if (_held) then {
    _cnt ctrlSetText "IN HAND";
} else {
    _cnt ctrlSetText (if (_n > 0) then { format ["x%1", _n] } else { "EMPTY" });
};
