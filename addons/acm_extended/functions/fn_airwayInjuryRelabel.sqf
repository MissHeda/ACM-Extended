/* Append clinical airway patency to established airway devices in the Head injury list.
   _entries is passed by reference by ACE's updateInjuryListPart event. */
params ["_ctrl", "_target", "_selectionN", "_entries"];
if (isNull _target || {_selectionN != 0}) exitWith {};

// Device rows report only what is visibly established. Patency remains an assessment finding and is only
// disclosed after the provider actually uses Check Airway.
private _suffix = "";
private _known = [localize "STR_ACM_Airway_NPA", localize "STR_ACM_Airway_OPA", localize "STR_ACM_Airway_IGel"];
{
    _x params ["_text", "_color"];
    if (_text in _known) then {_entries set [_forEachIndex, [_text + _suffix, _color]];};
} forEach _entries;

if (_target getVariable ["ACME_ETT_Inserted", false]) then {
    private _ettPrefix = "Endotracheal Tube";
    private _idx = _entries findIf {(((_x param [0, ""]) find _ettPrefix) == 0)};
    private _row = [_ettPrefix + _suffix, [0.19, 0.91, 0.93, 1]];
    if (_idx >= 0) then {_entries set [_idx, _row]} else {_entries pushBack _row};
};
