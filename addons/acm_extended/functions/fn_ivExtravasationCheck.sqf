// decide whether a newly placed iv will extravasate because it sits distal to, meaning below, a compromised site on
// the same limb. venous blood flows distal to proximal, toward the heart, so a drug pushed through an iv placed
// below a hole, from a miss or the venotomy of a removed iv, flows up and leaks out that hole. placing the iv
// proximal to every compromised site avoids this, however far above, and it can be the same vein, simply
// physically higher.
// the anatomy is encoded two ways that must both matter.
// 1. the site tier: upper, the most proximal, then middle, the ac fossa, then lower, the cephalic and dorsal arch,
// the most distal.
// 2. the exact vertical position of the individual attempt within a tier.
// the front and rear limb views do not share a v coordinate space, so we compare a canonical height built from the
// tier, which dominates, plus the intra-view v as a fine offset. a smaller canonical height is more proximal.
// call it as [_patient, _newSite, _newV] call ACME_fnc_ivExtravasationCheck, which returns a bool where true means
// this iv will extravasate.
params ["_patient", ["_newSite", "lower"], ["_newV", 0.5]];
// the system toggle, read live, so unticking iv placement anatomy in addon options stops this system immediately
// and completely with no mission restart.
if !(missionNamespace getVariable ["ACME_sys_ivplacement", true]) exitWith { false };  // it returns a boolean to the caller, so off means it never leaks rather than nil.
if (isNull _patient) exitWith { false };

private _bp   = toLower (uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"]);
private _view = uiNamespace getVariable ["ACME_IV_View", ""];

// the canonical vertical height for a [tier, rawv] pair. the tier sets a wide band, with upper at 0.0, middle at
// 1.0 and lower at 2.0, and the raw v nudges within plus or minus 0.5, so two attempts in the same tier still
// order by their real position. the result grows downward, distally, so a smaller number is more proximal, higher
// on the limb.
// this is a within-limb ordering and not an ACM access site, so it stays local and deliberately keeps its own
// default of middle. do not replace it with ACME_fnc_ivSiteIndex.
private _fnc_canon = {
    params ["_tier", "_v"];
    private _base = switch (toLower _tier) do {
        case "upper":  { 0 };
        case "middle": { 1 };
        case "lower":  { 2 };
        default { 1 };
    };
    // map the raw v, roughly 0.15 to 0.75 across the art, into a -0.5 to +0.5 fine offset, so the within-tier ordering
    // holds.
    _base + (((_v - 0.15) / 0.60) - 0.5)
};

private _newCanon = [_newSite, _newV] call _fnc_canon;

// the external jugular is filed against the head and carries a side rather than a height, so it is recognized
// from the body part rather than from the site name.
private _isEJ = (_bp == "ej") || {_bp == "head"} || {uiNamespace getVariable ["ACME_IV_EJMode", false]};

private _marks = _patient getVariable ["ACME_IV_Marks", []];
private _leaks = false;
{
    _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""], ["_mframe", ""], ["_mgauge", 0], ["_mmiss", -1], ["_mscale", 1], ["_msite", "lower"]];
    // only compromised sites on the same limb count: a miss, or the hole of a removed iv. an active hub does not make a
    // distal iv leak, because both can be patent. skip the mark we are about to place, and any on other limbs.
    private _sameEJSide = (!_isEJ) || {(toLowerANSI _msite) == (toLowerANSI _newSite)};
    if ((toLower _mbp) == _bp && {_mkind in ["miss", "removed"]} && {_sameEJSide}) then {
        private _markCanon = [_msite, _mv] call _fnc_canon;
        // a compromised site is proximal to, above, the new iv when its canonical height is smaller. a small epsilon avoids
        // flagging a hole at essentially the same height, because a re-stick right at the old spot is handled separately
        // by the exact-spot block in the minigame.
        // the ej runs the other way and has to be compared the other way.
        // a limb drains distal to proximal, so a hole above a new iv is downstream of it and leaks. the external
        // jugular drains from the head down to the subclavian, so downstream is toward the clavicle. a stick above
        // a hole pushes fluid down through that hole and leaks. a stick below one is downstream of the damage
        // entirely and is a perfectly good site.
        // the canonical height grows downward in both cases, so the ej is the same test with the sign flipped.
        private _leak = if (_isEJ) then {
            _markCanon > (_newCanon + 0.03)
        } else {
            _markCanon < (_newCanon - 0.03)
        };
        if (_leak) exitWith { _leaks = true; };
    };
} forEach _marks;

_leaks
