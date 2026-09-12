// set the status and instruction line, idc 86322, at the bottom of the kit dialog.
params ["_text"];
private _display = uiNamespace getVariable ["ACME_SK_DLG", displayNull];
if (isNull _display) exitWith {};
private _ctrl = _display displayCtrl 86322;
if (!isNull _ctrl) then {_ctrl ctrlSetText _text;};
