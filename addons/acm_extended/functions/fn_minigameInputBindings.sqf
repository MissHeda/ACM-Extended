/* Resolve at input time so profile edits and alternative bindings are respected.
   actionKeysEx supplies [main, combo, doubleTap]. CBA getKeybind field 8 contains all binds. */
params [["_display", displayNull, [displayNull]]];
private _out = [];
{
    if (_x isEqualType [] && {count _x >= 3}) then {
        _x params [["_main", [], [[]]], ["_combo", [], [[]]], ["_double", false, [true]]];
        if (count _main >= 2 && {(_main select 0) isEqualType 0} && {(_main select 1) isEqualType ""}) then {
            _out pushBack ["nv", _main, _combo, _double, []];
        };
    };
} forEach (actionKeysEx "NightVision");
if (!isNull _display && {_display isEqualTo (findDisplay 87700)} && {!isNil "CBA_fnc_getKeybind"}) then {
    private _data = ["ACM Extended", "ACME_vent_flipDevice"] call CBA_fnc_getKeybind;
    if (isNil "_data" || {!(_data isEqualType [])}) then {_data = [];};
    private _binds = _data param [8, [], [[]]];
    if (_binds isEqualTo [] && {count _data > 5}) then {_binds = [_data select 5];};
    {
        if (_x isEqualType [] && {count _x == 2}) then {
            _x params [["_key", -1, [0]], ["_mods", [], [[]]]];
            if (_key > 0 && {_key < 250} && {count _mods == 3} && {{_x isEqualType true} count _mods == 3}) then {
                private _main = [_key, "KEYBOARD"];
                if (_key >= 240 && {_key <= 247}) then {_main = [_key - 240, "MOUSE_BUTTON"];};
                if (_key == 248) then {_main = [0, "ACME_WHEEL"];};
                if (_key == 249) then {_main = [1, "ACME_WHEEL"];};
                _out pushBack ["flip", _main, [], false, _mods];
            };
        };
    } forEach _binds;
};
_out
