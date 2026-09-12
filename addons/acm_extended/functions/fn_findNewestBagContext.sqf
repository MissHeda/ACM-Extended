params ["_patient", "_bodyPart", "_selectedIV", "_accessSite", ["_volume", -1]];

private _bags = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _bodyPartBags = _bags getOrDefault [_bodyPart, []];

// the crystalloid carrier types a drug can be infused in. the 250, 500 and 1000 ml bags of the mod are type
// "PlasmaLyte", and only the 50 and 100 ml bags are type "Saline", so a Saline-only filter excluded every prepared
// PlasmaLyte bag. it therefore never matched the freshly-hung bag and stayed a plain fluid in the transfusion menu
// instead of becoming an infusion.
private _carriers = missionNamespace getVariable ["ACME_infusion_carrierTypes", ["Saline", "PlasmaLyte"]];

private _exact = [];  // newest carrier bag matching the requested volume (preferred)
private _any   = [];  // newest carrier bag at this access site, any volume (robust fallback)

{
    _x params ["_type", "_remainingVolume", "_accessType", "_bagAccessSite", "_bagIV", ["_bloodType", -1], ["_originalVolume", 0], ["_freshBloodID", -1]];
    if ((_type in _carriers) && {_bagIV == _selectedIV} && {_bagAccessSite == _accessSite}) then {
        private _ctx = [_patient, _bodyPart, _forEachIndex, _type, _accessType, _bagAccessSite, _bagIV, _bloodType, _originalVolume, _freshBloodID, _remainingVolume, (_x param [8, ""])];
        _any = _ctx;
        if ((_volume < 0) || {_originalVolume == _volume}) then { _exact = _ctx; };
    };
} forEach _bodyPartBags;

// prefer the exact-volume match, and otherwise fall back to the newest carrier bag at this access site. the medic
// just hung this bag here, so the newest crystalloid at this site is the right one even if the volume token did
// not line up.
if !(_exact isEqualTo []) then { _exact } else { _any }
