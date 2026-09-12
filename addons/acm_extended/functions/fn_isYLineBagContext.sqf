// true for a physical bag that belongs to a blood y-tubing set: the blood limb or the paired saline reserve.
params [["_context", [], [[]]]];
if (_context isEqualTo []) exitWith {false};

_context params [
    ["_patient", objNull],
    ["_bodyPart", ""],
    ["_bagIndex", -1],
    ["_type", ""],
    ["_accessType", 0],
    ["_bagAccessSite", -1],
    ["_bagIV", true],
    ["_bloodType", -1],
    ["_volume", 0],
    ["_freshBloodID", -1],
    ["_remainingVolume", 0]
];

private _typeLC = toLowerANSI _type;

// once a saline reserve has been retagged, the type alone is authoritative.
// these are lowercased classnames. they are compared against the tolower of a bag type, so they carry the prefix in
// lower case and a case-sensitive rename slid straight past them. left alone they would have silently stopped
// matching, and y-line detection would have failed with nothing in the RPT to say why.
if (_typeLC in ["acme_saliney", "acme_emptysaline"]) exitWith {true};

private _isRelevantYCarrier = (_type in ["Blood", "FreshBlood"]) || {_typeLC == "saline"};
if (!_isRelevantYCarrier) exitWith {false};

[_patient, _bodyPart, _bagIV, _bagAccessSite] call ACME_fnc_isYLineAccess
