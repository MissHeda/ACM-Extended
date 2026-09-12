params ["_medication", "_dose"];

private _unit = "mg";
private _value = _dose;

if (_value >= 1000) then {
    _value = _value / 1000;
    _unit = "g";
} else {
    // sub-milligram doses, for fentanyl and other mcg-range drugs, read as a confusing "0.05mg", so show them in
    // mcg.
    if (_value != 0 && {(abs _value) < 1}) then {
        _value = _value * 1000;
        _unit = "mcg";
    };
};

private _rounded = round _value;
private _text = if (abs (_value - _rounded) < 0.01) then {
    str _rounded
} else {
    if (_value < 10) then {
        private _s = _value toFixed 2;
        while {(_s select [(count _s) - 1, 1]) == "0"} do {_s = _s select [0, (count _s) - 1]};
        if ((_s select [(count _s) - 1, 1]) == ".") then {_s = _s select [0, (count _s) - 1]};
        _s
    } else {
        _value toFixed 1
    };
};

format ["%1%2", _text, _unit]
