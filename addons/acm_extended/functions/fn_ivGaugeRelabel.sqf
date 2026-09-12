// Correct only the unknown-gauge rows emitted by ACM gui/overrides/fnc_updateInjuryList.sqf:339-343.
// The event calls this before EJ and descriptor relabels. The site identifies each catheter independently.
// _entries is the live row array; only text is changed. Colors and connected-bag suffixes are retained.
params [["_entries", [], [[]]], ["_types", [], [[]]]];
if (_entries isEqualTo [] || {(_types findIf {_x in [5, 6]}) < 0}) exitWith {_entries};
private _labels = [
    localize "STR_ACM_Circulation_IV_Upper",
    localize "STR_ACM_Circulation_IV_Middle",
    localize "STR_ACM_Circulation_IV_Lower"
];
{
    private _entryIndex = _forEachIndex;
    private _row = _x;
    if !(_row isEqualType [] && {count _row >= 2}) then {continue;};
    private _text = _row select 0;
    if !(_text isEqualType "") then {continue;};
    if ((toLower (_text select [0, 6])) isNotEqualTo "true (") then {continue;};
    private _low = toLower _text;
    private _site = _labels findIf {(_low find (toLower ("true (" + _x + ")"))) == 0};
    if (_site < 0) then {continue;};
    private _gauge = switch (_types param [_site, 0]) do {
        case 5: {"18g IV"};
        case 6: {"20g IV"};
        default {""};
    };
    if (_gauge isEqualTo "") then {continue;};
    private _copy = +_row;
    _copy set [0, _gauge + " " + (_text select [5])];
    _entries set [_entryIndex, _copy];
} forEach _entries;
_entries
