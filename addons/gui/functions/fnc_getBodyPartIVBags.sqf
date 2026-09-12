// ACM Extended fork-native implementation of ACM_GUI_fnc_getBodyPartIVBags.
// this is a de-macroed replacement of ACM's version plus one change: the bag types this addon adds are bucketed
// by what they actually are.
// re-pull and re-de-macro from the ACM source if ACM changes the buckets or the output format.
// call it as [_patient, _bodyPart, _iv, _accessSite, _accessType] call ACM_GUI_fnc_getBodyPartIVBags.
//
// the change.
// ACM sorts a bag by its type string and everything it does not recognize falls through to blood. the y line
// saline reserve is stored as ACME_SalineY, and the two spent markers as ACME_Empty and ACME_EmptySaline, so all
// three were counted as blood. a casualty with a y set showed the saline reserve added to the blood total in the
// medical menu, and a spent bag kept counting after it was empty.
// ACME_SalineY is saline. the two empty markers are nothing, because a bag with no volume left in it is not
// being transfused.
params ["_patient", "_bodyPart", ["_iv", true], ["_accessSite", -1], ["_accessType", -1]];

private _bloodVolume = 0;
private _freshBloodVolume = 0;
private _plasmaVolume = 0;
private _salineVolume = 0;
private _FBTKVolume = 0;

private _accessBodyPart = (_patient getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_bodyPart, []];

private _fnc_add = {
    params ["_type", "_vol"];
    switch (_type) do {
        case "Plasma":     { _plasmaVolume = _plasmaVolume + _vol; };
        case "Saline":     { _salineVolume = _salineVolume + _vol; };
        // the addon's y line reserve. it is saline, and it is not blood.
        case "ACME_SalineY": { _salineVolume = _salineVolume + _vol; };
        // spent markers. they hold no volume and belong in no total.
        case "ACME_Empty":       {};
        case "ACME_EmptySaline": {};
        case "FBTK":       { _FBTKVolume = _FBTKVolume + _vol; };
        case "FreshBlood": { _freshBloodVolume = _freshBloodVolume + _vol; };
        default            { _bloodVolume = _bloodVolume + _vol; };
    };
};

{
    _x params ["_type", "_volumeRemaining", "_bagAccessType", "_bagAccessSite", "_bagIV"];
    if (_iv) then {
        if (_bagIV && {_bagAccessSite == _accessSite}) then { [_type, _volumeRemaining] call _fnc_add; };
    } else {
        if (!_bagIV) then { [_type, _volumeRemaining] call _fnc_add; };
    };
} forEach _accessBodyPart;

private _output = [];

if (_FBTKVolume > 0) then {
    _output pushBack format ["%1: %2ml", (localize "STR_ACM_Circulation_GUI_TransfusingVolume_FieldBloodTransfusionKit_Short"), floor _FBTKVolume];
};
if (_freshBloodVolume > 0) then {
    _output pushBack format ["%1: %2ml", (localize "STR_ACM_Circulation_GUI_TransfusingVolume_FreshWholeBlood_Short"), floor _freshBloodVolume];
};
if (_bloodVolume > 0) then {
    _output pushBack format ["%1: %2ml", (localize "STR_ACM_Circulation_GUI_TransfusingVolume_Blood_Short"), floor _bloodVolume];
};
if (_plasmaVolume > 0) then {
    _output pushBack format ["%1: %2ml", (localize "STR_ACM_Circulation_GUI_TransfusingVolume_Plasma_Short"), floor _plasmaVolume];
};
if (_salineVolume > 0) then {
    _output pushBack format ["%1: %2ml", (localize "STR_ACM_Circulation_GUI_TransfusingVolume_Saline_Short"), floor _salineVolume];
};

_output joinString " "
