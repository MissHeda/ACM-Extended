// rewrite the access site in an ACM medical-log line so the log agrees with the buttons and the body map.
// call it as _this call ACME_fnc_ivLogRelabel from inside the addToLog wrapper. it takes the wrapper's own
// argument array, [_patient, _type, _format, _args], and returns it either unchanged or with one string in
// _args swapped.
//
// why this exists. ACM writes the access site into three log lines and none of them switch on the descriptor
// setting, so a medic running hardcore saw "Median Cubital" on the button, "Median Cubital" on the body map,
// and "Upper" in the log for the same cannula:
//   fnc_setIV.sqf:179          the placement line
//   fnc_inspectIV.sqf:76       the inspection line
//   core/overrides/fnc_healingLogic.sqf:79   the auto-heal line
// all three end up here because fn_postInit already wraps ace_medical_treatment_fnc_addToLog for the EMMA
// contact marker, so there is one choke point rather than three overrides.
//
// the hard part is that NONE of the three passes the body part. the arg list is the medic name, the verb, the
// IV name and the site, and that is all. so the limb has to come from somewhere else. there are two sources,
// tried in order.
//
// FIRST, the body part the medic has selected in the medical menu. that covers setIV and inspectIV, because
// both are menu actions on the selected limb, and it is certain rather than inferred.
//
// SECOND, a stash written by the ACM_circulation_setIVLocal handler in fn_postInit. this exists for
// healingLogic, the auto-heal facility path, which runs with no menu open. r-11 and r-16 recorded that line
// as unreachable; that was not quite right. ACM's setIVLocal takes
//     ["_medic","_patient","_bodyPart","_type","_iv","_accessSite"]
// and healingLogic reads it at core/overrides/fnc_healingLogic.sqf:74 as params ["","","","","_iv",
// "_accessSite"], discarding the body part it already has. It also fires the treatment event at line 62 and
// only then writes the log at line 65 onward, on the same frame, so a stash written by an event handler is
// present and current by the time this runs.
// the stash is deliberately NOT synced and is only trusted for a fraction of a second. if healingLogic runs on
// a machine where the patient is remote, the targetEvent lands elsewhere, no stash appears here, and the line
// falls back to plain Upper, Middle or Lower exactly as before. degrading to the old behavior is the correct
// failure, because the alternative is naming the wrong vein.
//
// scanning ACM_circulation_IV_Placement for a part carrying an IV at that site was the third option and was
// rejected: it is ambiguous when two limbs hold an IV at the same site, and it finds nothing at all on a
// removal, where the IV is gone by the time the line is written.
params [["_patient", objNull], ["_type", ""], ["_format", ""], ["_args", []]];
if (!(((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true))) exitWith { _this };
if (!(_args isEqualType [])) exitWith { _this };
if (_args isEqualTo []) exitWith { _this };

private _bp = "";

// source one: the menu selection.
if (!isNull (uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull])) then {
    private _sel = missionNamespace getVariable ["ace_medical_gui_selectedBodyPart", -1];
    if (_sel in [2, 3, 4, 5]) then {
        _bp = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] select _sel;
    };
};

// ACM localizes the site before it logs it, so match the localized strings rather than the keys.
private _plain = [
    localize "STR_ACM_Circulation_IV_Upper",
    localize "STR_ACM_Circulation_IV_Middle",
    localize "STR_ACM_Circulation_IV_Lower"
];

private _hit = -1;
private _site = -1;
{
    if (_x isEqualType "") then {
        private _f = _plain find _x;
        if (_f >= 0) then { _hit = _forEachIndex; _site = _f; };
    };
} forEach _args;

if (_hit < 0) exitWith { _this };

// source two: the setIVLocal stash, used only when the menu gave nothing. it must be fresh AND its access site
// must match the one actually found in this log line, so a stale or unrelated stash cannot relabel anything.
if (_bp isEqualTo "") then {
    private _stash = _patient getVariable ["ACME_ivLastSite", []];
    if ((count _stash) == 3) then {
        _stash params ["_sBp", "_sSite", "_sT"];
        if ((_sSite isEqualTo _site) && {(diag_tickTime - _sT) < 0.5}) then { _bp = _sBp; };
    };
};

if (_bp isEqualTo "") exitWith { _this };

private _name = [_bp, _site, false] call ACME_fnc_skSiteName;
if (_name isEqualTo "") exitWith { _this };

// copy rather than mutate. the caller's array may be a literal built at the ACM call site, and writing
// through it would edit whatever ACM does with it next.
private _out = +_args;
_out set [_hit, _name];
[_patient, _type, _format, _out]
