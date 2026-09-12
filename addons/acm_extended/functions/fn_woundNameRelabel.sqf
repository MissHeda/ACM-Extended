// clinical wound type names in the injury list.
// hooked on ace_medical_gui_updateInjuryListWounds, which ACM fires at gui/overrides/fnc_updateInjuryList.sqf:601
// with _woundEntries BY REFERENCE, after all five wound categories have been built at lines 594 to 598 and
// before they are appended into the list. so the rows can be rewritten before they are ever drawn.
//
// ACE deliberately dumbed three of these down for a general audience. its own config class names are Abrasion,
// Contusion and Laceration while the display strings read Scrape, Bruise and Tear, so hardcore is restoring
// ACE's own terminology rather than inventing any.
//
// SCOPE, per the inventory ruling:
//   TAKEN    Scrape, Bruise, Tear, Crushed Tissue
//   VANILLA  Cut and Velocity Wound stay exactly as ACE writes them, in both registers
//   already clinical, so untouched: Puncture Wound, Avulsion, Thermal Burn, and ACM's Chemical Burn
//
// leaving Cut alone is also the medically correct call. ACE's class is Cut, and the clinical alternative would
// be "incision", which implies a surgical edge that a bullet or a blast does not make.
//
// the swap is on the NOUN, not the whole string. the rows arrive as "2x Large Bruise", "[B] Minor Scrape",
// "Partial Large Tear", so replacing only the noun preserves the count prefix, the [B] [S] [C] [W] category
// tag and ACE's own size word. that matters because ACE is inconsistent about the size word: Abrasion_Minor is
// "Minor Scrape" but Laceration_Minor is "Small Tear". Rebuilding the string from scratch would have silently
// normalized one of those and changed text you did not ask to change.
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (!(((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true))) exitWith {};
if (_woundEntries isEqualTo []) exitWith {};

// none of the four nouns below appears inside any other ACE or ACM wound name, which is why a substring swap is
// safe here. checked against: Cut, Puncture Wound, Velocity Wound, Avulsion, Thermal Burn, Chemical Burn.
private _swaps = [
    ["Crushed Tissue", "Crush Injury"],   // longest first, so it is matched before any shorter overlap
    ["Scrape",         "Abrasion"],
    ["Bruise",         "Contusion"],
    ["Tear",           "Laceration"]
];

{
    _x params ["_text", "_color"];
    private _new = _text;
    {
        _x params ["_from", "_to"];
        private _i = _new find _from;
        // a while rather than a single pass, because a row could in principle carry the noun twice. it stops
        // advancing past the replacement so it cannot loop on a substring of its own output.
        private _guard = 0;
        while {_i >= 0 && {_guard < 4}} do {
            _new = (_new select [0, _i]) + _to + (_new select [_i + (count _from)]);
            _i = _new find _from;
            _guard = _guard + 1;
        };
    } forEach _swaps;
    if (_new isNotEqualTo _text) then { _woundEntries set [_forEachIndex, [_new, _color]]; };
} forEach _woundEntries;
