// the instructor-side RESET button handler. it resets the megacode dummy, the uinamespace target, to a clean
// baseline by driving the server-side reset core where the dummy is local, then toasts, logs and refreshes the
// panel.
private _d = uiNamespace getVariable ["ACME_MC_target", objNull];
if (isNull _d) exitWith {};

[_d] remoteExec ["ACME_fnc_megacodeResetUnit", _d];

["Megacode reset to baseline.", 2] call ace_common_fnc_displayTextStructured;
[["Reset to baseline", "#9be08c"]] call ACME_fnc_megacodeLog;
[87300, (uiNamespace getVariable ["ACME_MC_page", "vitals"])] call ACME_fnc_megacodeMenu;
