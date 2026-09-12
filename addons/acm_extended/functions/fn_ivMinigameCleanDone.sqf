/* Mark this site as cleaned; the provider keeps the pad until choosing to put it down. */
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_IV_BodyRect", []]) isEqualTo []) exitWith {};
uiNamespace setVariable ["ACME_IV_Cleaned", true];
