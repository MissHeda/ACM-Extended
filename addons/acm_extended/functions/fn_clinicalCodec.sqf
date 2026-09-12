/* [value, encode, clock-kind]. Produces JSON-safe arrays; never compiles input. */
params ["_value", ["_encode", true], ["_clock", ""], ["_depth", 0]];
if (_depth > 24) exitWith {if (_encode) then {["N"]} else {nil}};
if (!_encode && {_depth == 0} && {!([_value] call ACME_fnc_clinicalEncodedValid)}) exitWith {nil};
if (_encode) exitWith {
    if (_clock != "" && {_value isEqualType 0} && {finite _value} && {_value >= 0}) exitWith {
        ["T", _clock, _value - (if (_clock == "time") then {time} else {CBA_missionTime})]
    };
    switch (typeName _value) do {
        case "SCALAR": {if (finite _value) then {["V", _value]} else {["N"]}};
        case "BOOL";
        case "STRING": {["V", _value]};
        case "OBJECT": {["O", netId _value]};
        case "ARRAY": {["A", _value apply {[_x, true, "", _depth + 1] call ACME_fnc_clinicalCodec}]};
        case "HASHMAP": {["M", (keys _value) apply {[_x, [_value get _x, true, "", _depth + 1] call ACME_fnc_clinicalCodec]}]};
        default {["N"]};
    }
};
if !(_value isEqualType [] && {count _value > 0}) exitWith {nil};
switch (_value param [0, ""]) do {
    case "V": {_value param [1, 0]};
    case "O": {objectFromNetId (_value param [1, "0:0"])};
    case "T": {(if ((_value param [1, "cba"]) == "time") then {time} else {CBA_missionTime}) + (_value param [2, 0])};
    case "A": {(_value param [1, []]) apply {[_x, false, "", _depth + 1] call ACME_fnc_clinicalCodec}};
    case "M": {private _m = createHashMap; {_m set [_x select 0, [_x select 1, false, "", _depth + 1] call ACME_fnc_clinicalCodec];} forEach (_value param [1, []]); _m};
    default {nil};
}
