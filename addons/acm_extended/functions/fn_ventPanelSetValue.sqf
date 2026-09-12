// write one value field, live, while the dial is turning it.
// the knob used to write the whole row back into the row control, as
// (_dlg displayctrl 87781) ctrlSetText format ["LOW RR        %1 BPM", _v];
// which would now stamp the label and the value back into one string and quietly undo the label and value split the
// moment you touched the dial. the row would go back to lighting up whole, and it would look like the fix had simply
// not worked.
// call it as [_row, "6 BPM"] call ACME_fnc_ventPanelSetValue.
params [["_row", -1], ["_text", ""]];
disableSerialization;

private _fields = uiNamespace getVariable ["ACME_vent_valFields", []];
if (_row < 0 || {_row >= (count _fields)}) exitWith {};

private _f = _fields select _row;
if (isNull _f) exitWith {};

// every value field is a plain control created by fn_ventpanelvaluefields, the ALERTS ones included since 0.9.758,
// so the write is always direct. the colors are untouched here: the highlight state stays exactly as the list
// painter left it while the dial turns the number underneath.
_f ctrlSetText _text;
_f ctrlCommit 0;
