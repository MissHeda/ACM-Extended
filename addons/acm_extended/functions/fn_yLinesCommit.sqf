/* Authoritative mutation gate for Y-line membership topology. */
params [["_patient",objNull,[objNull]],["_lines",[],[[]]],["_public",true,[true]]];
if (isNull _patient) exitWith {false};
_patient setVariable ["ACME_YLines", _lines, _public];
true
