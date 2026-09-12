// name an access site.
// call it as [_bodyPart, _accessSite, _isIO] call ACME_fnc_skSiteName, which returns "Median Cubital", "Middle" and
// so on. the hardcore name comes from fn_ivveincatalog and the plain one is still upper, middle or lower.
// hardcore descriptors give the anatomy, and outside hardcore the plain upper, middle and lower is kept, which is
// the same rule fn_ivsiterelabel already applies to the medical-menu action buttons. both read the same names, so
// the body map and the buttons can never disagree about what a site is called.
// a fast io gets its own name because it is not an iv site at all: the humeral head on an arm, the tibial tuberosity
// on a leg and the sternum on the torso.
params ["_bodyPart", ["_site", 0], ["_isIO", false]];
private _bp = toLower _bodyPart;

// The IV minigame stores sites as "upper", "middle" or "lower", while the body map and ACM use
// numeric access indexes. Accept both here. NA8 passed the minigame String directly into the numeric max/min
// expression below, which stopped peripheral IV initialization immediately after INIT SITE OK. EJ did not hit
// that path because its vein setup is handled separately.
private _siteIdx = if (_site isEqualType "") then {
    switch (toLower _site) do {
        case "upper": { 0 };
        case "middle": { 1 };
        case "lower": { 2 };
        default { 1 };
    };
} else {
    if (_site isEqualType 0) then { ((round _site) max 0) min 2 } else { 1 };
};
private _hc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
private _isArm = _bp in ["leftarm", "rightarm"];
private _isLeg = _bp in ["leftleg", "rightleg"];

if (_isIO) exitWith {
    if (!_hc) exitWith { "IO" };
    switch (true) do {
        case (_isArm): { "Humeral Head IO" };
        case (_isLeg): { "Tibial Tuberosity IO" };
        default        { "Sternal FAST1 IO" };
    };
};

if (!_hc) exitWith { ["Upper", "Middle", "Lower"] select _siteIdx };

// the vein, from the one catalog, so this name can never disagree with the difficulty model, the action buttons,
// the injury list, the transfusion header or the medical log. every one of those now resolves through here.
// the naming follows the ART, because fn_ivSiteData bakes the band and vein UVs against the real canvas and
// fn_ivMinigameInit groups sites by shared view texture. that pins the upper arm site to the REAR view high on
// the arm, which is the basilic, and the middle to the FRONT view at the elbow, which is the median cubital.
// an earlier revision named the upper site for the antecubital fossa, which put the front of the elbow on the
// back of the upper arm and shifted every arm level one notch distal.
private _vein = [_bodyPart, _site] call ACME_fnc_ivVeinCatalog;
if ((count _vein) == 0) exitWith { ["Upper", "Middle", "Lower"] select _siteIdx };
_vein getOrDefault ["name", "Vein"]
