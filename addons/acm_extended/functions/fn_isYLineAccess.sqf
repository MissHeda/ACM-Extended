// true when the selected access site is a blood y-tubing line.
// the y line keys are stored as bodypart#isiv#accesssite.
params [
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "", [""]],
    ["_iv", true, [true]],
    ["_accessSite", -1, [0]]
];

if (isNull _patient || {_bodyPart isEqualTo ""}) exitWith {false};

private _yLines = (_patient getVariable ["ACME_YLines", []]) apply {toLowerANSI _x};
if (_yLines isEqualTo []) exitWith {false};

private _key = toLowerANSI (format ["%1#%2#%3", _bodyPart, _iv, _accessSite]);
if (_key in _yLines) exitWith {true};

// this is a fallback only when the caller has no concrete access-site index. exact site matching above is preferred,
// so a separate normal iv on the same limb is not treated as part of the y set.
if (_accessSite < 0) exitWith {
    private _prefix = toLowerANSI (format ["%1#%2#", _bodyPart, _iv]);
    (_yLines findIf {(_x find _prefix) == 0}) >= 0
};

false
