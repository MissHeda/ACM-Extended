/* Read both old single-drug records and new per-drug mixtures.
   Components are [medication, remaining dose in the configured unit, injection count]. */
params [["_entry", [], [[]]]];
private _components = _entry param [14, [], [[]]];
if (_components isEqualTo []) then {
    private _med = _entry param [3, "", [""]];
    private _dose = _entry param [4, 0, [0]];
    if (_med != "" && {_dose > 0} && {finite _dose}) then {_components = [[_med, _dose, 1]];};
};
_components apply {+_x}
