// The owning display's unload is the single return path for both dialog modes.
// Do not close an unrelated dialog or schedule a second competing menu reopen.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _display || {_display getVariable ["ACME_IV_Done", false]}) exitWith {};
_display setVariable ["ACME_IV_Done", true];
_display closeDisplay 1;
[] call ACME_fnc_aceCursorRestore;
