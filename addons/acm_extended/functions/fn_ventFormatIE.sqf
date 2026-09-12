// format an i:e ratio for display. the stored value is the e part per 1 part i, so 2.0 is 1:2.
// below 1.0 the ratio is inverse and the device shows it the way clinicians say it: 2:1 rather than 1:0.5.
// call it as [_ie] call ACME_fnc_ventFormatIE, which returns a string.
params ["_ie"];
if (_ie >= 1) then {
    format ["1:%1", _ie toFixed 1]
} else {
    format ["%1:1", (1 / _ie) toFixed 1]
};
