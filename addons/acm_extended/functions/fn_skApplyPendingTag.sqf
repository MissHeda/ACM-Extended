/* B60: attach the currently staged optional syringe tag to a prepared-syringe record.
   Slots 7-10 remain tag color + three text lines; slot 11 remains the B59 stable syringe ID. */
params [["_entry", [], [[]]]];
private _out = +_entry;
while {count _out < 11} do {_out pushBack "";};
private _color = uiNamespace getVariable ["ACME_SK_PendingTagColor", "none"];
if !(_color isEqualType "") then {_color = "none";};
private _lines = uiNamespace getVariable ["ACME_SK_PendingTagText", ["","",""]];
if !(_lines isEqualType []) then {_lines = ["","",""];};
while {count _lines < 3} do {_lines pushBack "";};
_out set [7, _color];
for "_i" from 0 to 2 do {_out set [8 + _i, (_lines param [_i, "", [""]]) select [0,25]];};
_out
