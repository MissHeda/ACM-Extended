// This function finds the IV site of a puncture. It uses the puncture point only.
// Call the function as [_u, _v] call ACME_fnc_ivSiteAtPoint.
// Call the function as [_u, _v, _view, _siteList] to test a different view.
// _u and _v are the body fractions of the needle tip at the moment of the stick.
// These are the same two values that ACME_IV_InsU and ACME_IV_InsV hold.
// The function returns the site name "upper", "middle" or "lower".
// The function returns "" if no site is near the point on this view.
//
// REASON FOR THIS FUNCTION.
// The registration read ACME_IV_Site before. That value is the site of the BAND.
// Each reader in the chain used a different default value for an unset site.
// There were eight different defaults. Three of them gave "lower".
// The launcher sets the value 'lower'. A stick in the antecubital fossa kept that value.
// The mod then recorded a lower cephalic IV.
// The site of a catheter is a property of the puncture point.
// Therefore this function measures the site from the puncture point only.
//
// The function returns the NEAREST site on the view. It applies no distance limit.
// A limit refuses a stick, and no code refuses a stick that the medic wants.
//
// The anchors come from ACME_IV_SiteList.
// fn_ivMinigameInit builds that list from fn_ivSiteData.
// Therefore this function holds no coordinates. The function cannot disagree with the art.
// A site list row is [site, view, bandU, bandV, veinU, veinV, label, bandTex].
//
// The view filter is necessary.
// An arm shows the lower and middle sites on the front view.
// An arm shows the upper site on the rear view.
// A leg shows the lower and upper sites on the front view.
// A leg shows the middle site on the rear view.
// A point resolves only to a site on the view that the medic sees.
//
// The function measures distance in raw body fractions. It applies no aspect correction.
// The sites are in a line along the v axis.
// The ceiling below uses the same units as fn_ivSiteData.
params ["_u", "_v", ["_view", ""], ["_siteList", []]];
if (!(_u isEqualType 0) || {!(_v isEqualType 0)}) exitWith {""};
if (!finite _u || {!finite _v}) exitWith {""};

if (_view isEqualTo "") then { _view = uiNamespace getVariable ["ACME_IV_View", ""]; };
if (_siteList isEqualTo []) then { _siteList = uiNamespace getVariable ["ACME_IV_SiteList", []]; };
if (_view isEqualTo "" || {_siteList isEqualTo []}) exitWith {""};

private _best = "";
private _bestD = 1e9;
{
    if (_x isEqualType [] && {count _x >= 6}) then {
        _x params ["_sName", "_sView", "", "", "_vU", "_vV"];
        if (_sView isEqualTo _view && {_vU isEqualType 0} && {_vV isEqualType 0}) then {
            private _du = _u - _vU;
            private _dv = _v - _vV;
            private _d = sqrt ((_du * _du) + (_dv * _dv));
            if (_d < _bestD) then {
                _bestD = _d;
                _best = toLower _sName;
            };
        };
    };
} forEach _siteList;

// Return the nearest site. Do not test a distance limit.
// A limit here stops a stick, and the medic decides where to put a catheter.
_best
