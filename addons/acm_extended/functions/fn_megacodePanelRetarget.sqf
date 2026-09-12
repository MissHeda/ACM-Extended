// operator-side: after the manikin was respawned, point the open megacode panel at the new manikin and rebuild the
// current page, so the controls keep working without the operator having to close and re-open.
// it is a no-op if this client does not actually have the panel open, because the respawn fans out to the stored
// operator client only.
// _this is [_new].
params [["_new", objNull]];
if (isNull _new) exitWith {};
if (isNull (uiNamespace getVariable ["ACME_Megacode_DLG", displayNull])) exitWith {};  // panel not open here

uiNamespace setVariable ["ACME_MC_target", _new];
_new setVariable ["ACME_MC_operatorClient", player, true];

[["Manikin reset and ready.", "#9be08c"]] call ACME_fnc_megacodeLog;
[87300, (uiNamespace getVariable ["ACME_MC_page", "vitals"])] call ACME_fnc_megacodeMenu;
