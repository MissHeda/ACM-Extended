disableSerialization;
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (isNull _display) exitWith {};

// the top instruction line is retired, so the dialog carries no prompt text. the control is blanked rather than
// removed, so every existing call site stays valid.
(_display displayCtrl 86403) ctrlSetText "";
