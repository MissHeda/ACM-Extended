// conditional bleeding status.
// hooked on ace_medical_gui_updateInjuryListGeneral, which ACM fires at
// gui/overrides/fnc_updateInjuryList.sqf:172 with _entries by reference.
//
//   bleeding now                       ->  "Active hemorrhage"
//   not bleeding, but has bled before  ->  "Hemorrhage controlled"
//   never bled                         ->  "No significant hemorrhage"
//
// the third case is the reason this is not a two-line string swap. "Hemorrhage controlled" is a claim about
// treatment, and putting it on a casualty who was never hit says the medic achieved something they did not.
//
// TWO THINGS FOUND WHILE WIRING THIS, both of which change how it had to be built.
//
// 1. THIS IS WHOLE-PATIENT, NOT PER-LIMB. ACM puts both rows on the general tab at lines 32 to 50 using
//    IS_BLEEDING(_target), which reads ace_medical_woundBleeding for the whole unit. So "has bled before" is a
//    property of the casualty, and "Hemorrhage controlled" is a statement about the casualty rather than about
//    whichever limb happens to be selected.
//
// 2. IT IS ACM'S STRING, NOT ACE'S. ACM substitutes its own LLSTRING(NoExternalBleeding) at line 49 and never
//    uses ACE's STR_ACE_Medical_GUI_STATUS_NOBLEEDING at all. Wrapping the ACE key, which is what the first
//    draft of the inventory assumed, would have done nothing whatsoever. The row also only appears when ACM's
//    showInactiveStatuses setting is on, so on a clean casualty with that off there is simply no row to rewrite
//    and nothing here fires.
//
// ACE's Bleed_Rate1 to Bleed_Rate4 strings, the qualitative rate mode, are deliberately NOT touched. Neither
// are any of the Lost_Blood tiers, the tourniquet row or the NPA row.
params ["_ctrl", "_target", "_selectionN", "_entries"];
if (!(((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true))) exitWith {};
if (isNull _target) exitWith {};
if (_entries isEqualTo []) exitWith {};

private _bleedingNow = (_target getVariable ["ace_medical_woundBleeding", 0]) > 0;

// HAS THIS CASUALTY EVER BLED. no new state is stored for this; every source below already exists.
//   ace_medical_bandagedWounds   they bled and were bandaged
//   ACM_damage_ClottedWounds     ACM_damage_fnc_clotWoundsOnBodyPart writes this, and it is what our own
//                                direct pressure (fn_directPressureTick:62) and junctional wrap
//                                (fn_junctionalWrapDone:18) both call. without this entry a casualty held
//                                closed by pressure alone would have read "No significant hemorrhage".
//   ace_medical_stitchedWounds   and ACM_damage_WrappedWounds, the other two treated states
//   ace_medical_tourniquets      a limb controlled by tourniquet alone has no bandaged wound to find
//   ACME_Junc_<part>             our junctional bleed sits outside ACE's wound system entirely, so a packed
//                                groin would otherwise read as never having bled
private _everBled = false;

{
    if (!_everBled && {(count (_target getVariable [_x, createHashMap])) > 0}) then { _everBled = true; };
} forEach ["ace_medical_bandagedWounds", "ACM_damage_ClottedWounds", "ace_medical_stitchedWounds", "ACM_damage_WrappedWounds"];

if (!_everBled) then {
    // a tourniquet on an UNINJURED limb trips this and reads "Hemorrhage controlled" on a casualty who never
    // bled. that false positive is accepted deliberately: dropping this test would make a limb controlled by
    // tourniquet alone, with no bandage under it, read "No significant hemorrhage", which is the worse error of
    // the two because it understates a live problem.
    private _tqs = _target getVariable ["ace_medical_tourniquets", [0,0,0,0,0,0]];
    if ((_tqs findIf {_x isEqualType 0 && {_x > 0}}) > -1) then { _everBled = true; };
};

if (!_everBled) then {
    {
        if (!_everBled
            && {(_target getVariable [format ["ACME_Junc_%1", _x], ""]) in ["open", "packed", "wrapped", "xstat"]}) then {
            _everBled = true;
        };
    } forEach ["body", "leftarm", "rightarm", "leftleg", "rightleg"];
};

// match on the localized text, because both rows are already localized by the time they reach _entries.
private _bleedRow = localize "STR_ACE_Medical_GUI_STATUS_BLEEDING";
private _cleanRow = localize "STR_ACM_GUI_NoExternalBleeding";

{
    _x params ["_text", "_color"];
    private _new = "";
    if (_text isEqualTo _bleedRow) then { _new = "Active hemorrhage"; };
    if (_text isEqualTo _cleanRow) then {
        _new = ["No significant hemorrhage", "Hemorrhage controlled"] select _everBled;
    };
    // the color is kept as ACM set it. a controlled hemorrhage is still a resolved finding and belongs in the
    // same non-issue color as the row it replaces, and an active one keeps ACM's red.
    if (_new isNotEqualTo "") then { _entries set [_forEachIndex, [_new, _color]]; };
} forEach _entries;

// a rebleed needs no handling here. fn_clotPopTick restarts the bleed, ace_medical_woundBleeding goes above
// zero, ACM renders the bleeding row again and this flips back to "Active hemorrhage" on its own.
