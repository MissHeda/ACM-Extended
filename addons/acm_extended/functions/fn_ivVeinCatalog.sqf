// the vein at a given site, and what it is like to cannulate.
// call it as [_bodyPart, _site] call ACME_fnc_ivVeinCatalog, which returns a hashmap, or an empty one for an
// unknown combination.
// _bodyPart is "leftarm", "rightarm", "leftleg", "rightleg" or "ej". _site is 0 upper, 1 middle, 2 lower.
//
// the keys.
//   "name"     the clinical name, for the hardcore descriptors.
//   "short"    the shorthand a medic writes on a card and reads back in an AAR. it is the same in both
//              registers, because a flowsheet entry is shorthand in every register.
//   "plain"    what a layperson would call it.
//   "level"    where on the limb it is, so a medic reading a log knows which stick is being described.
//   "maxG"     the routine gauge threshold for the modeled oversize penalty, not a placement ban.
//   "oversizeTolerance" optional maximum normalized puncture error for an oversized catheter.
//   "caliber"  0 to 1, how large the lumen is. it widens the target.
//   "depth"    0 to 1, how deep it lies. it makes the vein harder to feel rather than harder to hit.
//   "roll"     0 to 1, how mobile it is. a rolling vein moves away from the needle and it is the single most
//              common reason a stick that looked right still misses.
//   "risk"     a short note on what is next to it, or "" when there is nothing worth saying.
//
// the sites are named for WHERE THE BAND IS PLACED. that is the whole rule and it does not need rederiving:
//   arm, band high and on the back      basilic
//   arm, band mid                       AC fossa
//   arm, band low toward the wrist      cephalic
//   leg, band high                      great saphenous
//   leg, band mid, back of the leg      popliteal
//   leg, band low                       dorsal arch
// this is what v0.9.999r-9 shipped and it was correct. r-11 replaced it with names derived from anatomy
// arguments instead, which renamed the leg sites and, worse, carried DIFFICULTY NUMBERS with the rename: the
// leg lower site went from caliber 0.80 / roll 0.20 / maxG 16 to caliber 0.35 / roll 0.75 / maxG 20. Since the
// minigame always opens on the lower site, every leg IV suddenly started on a target 4.2x smaller at the
// default 16g, missed, and infiltrated instead of placing. the numbers below are r-9's, per index, unchanged.
// _site is accepted as either the index or the name.
// the minigame stores it as a string, "upper", "middle" or "lower", and the body map and the treatment actions
// pass the index. taking both means neither caller has to convert, and a caller that passes the wrong one gets
// the right vein instead of a silent fallback to the middle of the limb.
params [["_bodyPart", ""], ["_site", 1]];
private _bp = toLower _bodyPart;
// a catalog row index rather than an ACM access site. it has no ej rows, so it must not gain the ej cases
// that ACME_fnc_ivSiteIndex carries.
private _s = if (_site isEqualType "") then {
    switch (toLower _site) do {
        case "upper":  { 0 };
        case "middle": { 1 };
        case "lower":  { 2 };
        default        { 1 };
    };
} else {
    ((round _site) max 0) min 2
};

private _mk = {
    params ["_n", "_p", "_l", "_mg", "_cal", "_dep", "_rol", ["_rk", ""], ["_sh", ""]];
    private _h = createHashMap;
    _h set ["name", _n]; _h set ["plain", _p]; _h set ["level", _l]; _h set ["short", _sh];
    _h set ["maxG", _mg]; _h set ["caliber", _cal]; _h set ["depth", _dep];
    _h set ["roll", _rol]; _h set ["risk", _rk];
    _h
};

// the external jugular. it is not a limb site and it has no upper, middle or lower.
// large and it will take a big cannula, and it is not a first choice: it needs the patient supine and head down,
// it collapses on inspiration, and it moves with every breath the casualty takes.
if (_bp == "ej") exitWith {
    ["External Jugular", "neck vein", "lateral neck, above the clavicle", 16, 0.85, 0.25, 0.55,
     "collapses on inspiration and moves with breathing", "EJ"] call _mk
};

private _isArm = _bp in ["leftarm", "rightarm"];
private _isLeg = _bp in ["leftleg", "rightleg"];
if (!_isArm && {!_isLeg}) exitWith { createHashMap };

if (_isArm) exitWith {
    switch (_s) do {
        // BAND HIGH AND ON THE BACK OF THE ARM. the basilic runs up the medial side and is the only superficial
        // vein of any size this high. large and shallow where the band sits.
        case 0: {
            ["Basilic", "upper arm vein", "medial upper arm", 14, 1.00, 0.10, 0.15,
             "brachial artery and median nerve run with it in the upper arm", "Bas"] call _mk
        };
        // BAND MID ARM. the antecubital fossa, at the front of the elbow. it crosses a joint, so a cannula here
        // kinks whenever the elbow bends.
        case 1: {
            ["AC Fossa", "inner elbow", "antecubital fossa", 16, 0.75, 0.15, 0.35,
             "brachial artery and median nerve lie deep and medial, and it kinks on elbow flexion", "AC"] call _mk
        };
        // BAND LOW, TOWARD THE WRIST. the cephalic runs up the lateral, thumb, side.
        default {
            // 16g, 18g and 20g use their normal gauge-scaled margins. A 14g is allowed,
            // but it must stay inside the central 15 percent of its hit radius.
            private _wrist = ["Cephalic", "forearm vein", "lateral forearm", 16, 0.35, 0.10, 0.75,
                "14g needs extremely accurate central placement; off-center placement blows the vein", "Ceph"] call _mk;
            _wrist set ["oversizeTolerance", 0.15];
            _wrist
        };
    };
};

switch (_s) do {
    // BAND HIGH ON THE LEG. the great saphenous is large here but has dropped under a layer of fat, so it is the
    // hardest of the three to find by feel even though it is the biggest.
    case 0: {
        ["Great Saphenous", "inner thigh vein", "medial thigh", 16, 0.85, 0.70, 0.30, "", "GSV"] call _mk
    };
    // BAND MID, ON THE BACK OF THE LEG. behind the knee.
    case 1: {
        ["Popliteal", "back of the knee", "popliteal fossa", 18, 0.55, 0.60, 0.40, "", "Pop"] call _mk
    };
    // BAND LOW, AT THE ANKLE AND FOOT.
    default {
        ["Dorsal Arch", "top of the foot", "dorsum of the foot", 16, 0.80, 0.30, 0.20, "", "DA"] call _mk
    };
};
