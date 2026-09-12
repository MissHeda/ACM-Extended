// name a body part for a log line or a hint.
// call it as [_bodyPart, _form] call ACME_fnc_bodyPartName.
// _bodyPart is the raw internal string, "head", "body", "leftarm", "rightarm", "leftleg", "rightleg". an ACE
// index 0 to 5 is accepted too, because half the addon carries the index and half carries the string and making
// every caller convert is how the seven divergent site mappings happened.
// _form is "display", "short", "long", or "abbr".
//
// "display"  the ACE display name, Left Arm, through ACM_core_fnc_getBodyPartString. this is what every caller
//            should use outside hardcore, and it is what several log lines SHOULD have been using all along:
//            fn_directPressureLimb, fn_directPressureSelf, fn_directPressureStop, fn_junctionalInflict,
//            fn_place18g and six others were passing the raw internal string straight into format, so the
//            medical log read "leftarm". that is wrong in both registers and is fixed regardless of setting.
// "short"    the provider abbreviation, LUE, RUE, LLE, RLE. hardcore only. this is what somebody actually
//            writes on a card or says on a radio, and it is the whole point of the log pass.
// "long"     the spelled-out anatomical region, Left Upper Extremity. hardcore only. this is for the injury
//            list header, where there is room and where a student benefits from seeing the term written out
//            rather than only its abbreviation.
//
// outside hardcore "short" falls back to the display name, so a caller can ask for the abbreviation
// unconditionally and get the right register without testing the flag itself.
params [["_bodyPart", ""], ["_form", "display"]];

private _parts = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"];
private _bp = if (_bodyPart isEqualType 0) then {
    _parts param [((round _bodyPart) max 0) min 5, ""]
} else {
    toLower _bodyPart
};
if (_bp isEqualTo "") exitWith { "" };

private _display = if (isNil "ACM_core_fnc_getBodyPartString") then {
    // ACM absent. this should not happen in a live build, because the addon requires ACM, but a missing
    // function returns nil rather than erroring and a nil in a format string prints as "any".
    ["Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"] param [_parts find _bp, _bp]
} else {
    [_bp] call ACM_core_fnc_getBodyPartString
};

if (_form isEqualTo "abbr") exitWith {
    switch (_bp) do {
        case "leftarm":  { "LUE" };
        case "rightarm": { "RUE" };
        case "leftleg":  { "LLE" };
        case "rightleg": { "RLE" };
        default          { _display };
    };
};

if (!(_form in ["short", "long"])) exitWith { _display };
if (!(((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true))) exitWith { _display };

if (_form isEqualTo "long") exitWith {
    switch (_bp) do {
        case "leftarm":  { "Left Upper Extremity" };
        case "rightarm": { "Right Upper Extremity" };
        case "leftleg":  { "Left Lower Extremity" };
        case "rightleg": { "Right Lower Extremity" };
        // head and torso are already the terms a provider uses. "Thorax and Abdomen" for the torso was
        // considered and dropped: ACE's torso hitbox is not a thorax, and naming it one would be more precise
        // than the model underneath it actually is.
        default          { _display };
    };
};

// the head and the torso keep their ordinary names. nobody abbreviates those, and "H" and "T" would be worse
// than useless in a log line.
switch (_bp) do {
    case "leftarm":  { "LUE" };
    case "rightarm": { "RUE" };
    case "leftleg":  { "LLE" };
    case "rightleg": { "RLE" };
    default          { _display };
};
