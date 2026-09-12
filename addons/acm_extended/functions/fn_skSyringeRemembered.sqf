/* B76: provider-facing syringe memory. The three newest drawn syringes remain identifiable without a tag.
   Older syringes are still fully valid medication records, but an untagged/unmarked one is presented as "???".
   Any real tag color or handwritten tag text permanently identifies that syringe until it is consumed/discarded. */
params [
    ["_store", [], [[]]],
    ["_idx", -1, [0]]
];
private _n = count _store;
if (_idx < 0 || {_idx >= _n}) exitWith {false};
private _e = _store select _idx;
private _color = _e param [7,"none",[""]];
private _marked = !(_color in ["","none"]);
if (!_marked) then {
    for "_i" from 8 to 10 do {
        private _txt = _e param [_i,"",[""]];
        if (((toArray _txt) findIf {_x > 32}) >= 0) exitWith {_marked = true;};
    };
};
_marked || {_idx >= ((_n - 3) max 0)}
