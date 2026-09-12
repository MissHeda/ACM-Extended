/* Pure event/binding match. Preserve modifiers and avoid plain-key matches on chords. */
params [["_binding", [], [[]]], ["_device", "KEYBOARD", [""]], ["_key", -1, [0]],
    ["_mods", [false,false,false], [[]], 3], ["_held", [], [[]]]];
if (count _binding != 5) exitWith {false};
_binding params ["_action", "_main", "_combo", "_double", "_required"];
if (count _main < 2) exitWith {false};
_main params [["_code", -1, [0]], ["_dev", "", [""]]];
if (_dev == "MOUSE_BUTTON") then {_code = _code mod 128;};
if (_dev != _device || {_code != _key}) exitWith {false};
private _actual = +_mods;
// The main key may itself be a modifier. Ignore only that key's modifier flag.
if (_device == "KEYBOARD") then {
    if (_key in [42,54]) then {_actual set [0,false];};
    if (_key in [29,157]) then {_actual set [1,false];};
    if (_key in [56,184]) then {_actual set [2,false];};
};
if !(_required isEqualTo []) exitWith {_actual isEqualTo _required};
private _want = [false,false,false];
private _comboOK = _combo isEqualTo [];
if (count _combo >= 2) then {
    _combo params [["_ck", -1, [0]], ["_cd", "", [""]]];
    if (_cd == "MOUSE_BUTTON") then {_ck = _ck mod 128;};
    _comboOK = format ["%1:%2", _cd, _ck] in _held;
    if (_cd == "KEYBOARD") then {
        if (_ck in [42,54]) then {_want set [0,true]; _comboOK = _mods select 0;};
        if (_ck in [29,157]) then {_want set [1,true]; _comboOK = _mods select 1;};
        if (_ck in [56,184]) then {_want set [2,true]; _comboOK = _mods select 2;};
    };
};
_comboOK && {_actual isEqualTo _want}
