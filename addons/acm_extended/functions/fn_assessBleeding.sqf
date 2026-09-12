// return a short bleeding descriptor for a body part, read from the open-wound map of ACM,
// ace_medical_openWounds, keyed by the lowercase part, where each wound is [id, amountof, bleeding, damage].
params ["_patient", "_bodyPart"];
if (isNull _patient) exitWith { "unknown" };

private _open = _patient getVariable ["ace_medical_openWounds", createHashMap];
if !(_open isEqualType createHashMap) exitWith { "unknown" };

private _onPart = _open getOrDefault [toLower _bodyPart, []];
private _total = 0;
{
    _x params ["", ["_amt", 0], ["_bleed", 0]];
    _total = _total + (_amt * _bleed);
} forEach _onPart;

switch (true) do {
    case (_total <= 0):    { "no active bleeding" };
    case (_total < 0.5):   { "minor bleeding" };
    case (_total < 1.5):   { "moderate bleeding" };
    default                { "severe bleeding" };
};
