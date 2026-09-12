// the site text for an activity-log line. it reads "L GSV", "R AC" or "L EJ".
// call it as [_bodyPart, _site] call ACME_fnc_ivLogSite, which returns the text, or "" when the limb and the site
// give nothing at all.
// _bodyPart is an ACM body part, or "ej". _site is "upper", "middle" or "lower", or the index 0, 1 or 2, or
// "left" or "right" for the ej. ACME_fnc_ivVeinCatalog takes either form, so this function takes both as well.
//
// there is ONE copy of this on purpose. the placement line and the removal line must read the same, and two
// copies of the same six lines is exactly how they stop reading the same. that is the recurring fault on this
// addon: a value written by hand in a second place and then left behind when the first one changes.
params [["_bodyPart", ""], ["_site", 1]];
private _bp = toLower _bodyPart;

if (!((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true)) exitWith {
    if (_bp isEqualTo "ej") exitWith {
        private _right = if (_site isEqualType "") then {(toLower _site) isEqualTo "right"}
            else {(_site isEqualType 0) && {_site == 1}};
        ["Left neck", "Right neck"] select _right
    };
    if !(_bp in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {""};
    format ["%1 (%2)", [_bp, "display"] call ACME_fnc_bodyPartName,
        [_bp, _site, false] call ACME_fnc_skSiteName]
};

private _side = "";
if (_bp in ["leftarm", "leftleg"]) then { _side = "L"; };
if (_bp in ["rightarm", "rightleg"]) then { _side = "R"; };
if (_bp isEqualTo "ej") then {
    // the ej site IS the side. it is the anatomical side of the patient, which
    // fn_ivMinigameStickSuccess locks, and not the side of the art, which is mirrored.
    private _s = if (_site isEqualType "") then {
        toLower _site
    } else {
        ["left", "right"] param [(((round _site) max 0) min 1), "left"]
    };
    _side = if (_s isEqualTo "right") then { "R" } else { "L" };
};

private _short = ([_bp, _site] call ACME_fnc_ivVeinCatalog) getOrDefault ["short", ""];
if (_short isEqualTo "") exitWith { _side };
if (_side isEqualTo "") exitWith { _short };
format ["%1 %2", _side, _short]
