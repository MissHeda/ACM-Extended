// one place for every piece of clinical wording.
// call it as [_category, _key] call ACME_fnc_medDescriptor, which returns the string to show.
// hardcore descriptors say what a clinician would say, and everything else says what a layperson would understand.
// both live here, side by side, so the menu and the readouts can never drift apart. that is the same reason
// fn_sksitename exists for the body map, and it is why the map and the action buttons agree about site names.
// what is deliberately not in here: procedure names that are already correct. perform thoracostomy and insert chest
// tube say exactly what they are, and renaming things that are already right is churn.
params ["_cat", "_key"];
private _hc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);

private _tbl = switch (toLower _cat) do {

    // skin.
    // the color, temperature and moisture are three separate findings and a medic reports all three. the plain version
    // collapses them, because outside hardcore that detail is noise.
    case "skin": {
        createHashMapFromArray [
            ["normal",     ["Skin looks normal",                    "Warm, dry, well perfused"]],
            ["pale",       ["Skin is pale",                         "Pale, cool, dry"]],
            ["clammy",     ["Skin is cold and clammy",              "Cool and diaphoretic, delayed refill"]],
            ["mottled",    ["Skin is blotchy and gray",             "Mottled, cool to the knee, poorly perfused"]],
            ["cyanotic",   ["Lips and fingers look blue",           "Peripheral cyanosis, nail beds dusky"]],
            ["central",    ["Lips and tongue look blue",            "Central cyanosis"]],
            ["flushed",    ["Skin is flushed and hot",              "Flushed, hot, dry"]],
            ["jaundiced",  ["Skin looks yellow",                    "Jaundiced, scleral icterus"]]
        ]
    };

    // pupils.
    // PERRL is the single most useful abbreviation a medic learns, and it means nothing until somebody sees it written
    // next to what it describes.
    case "pupils": {
        createHashMapFromArray [
            ["normal",     ["Pupils are equal and react to light",  "PERRL"]],
            ["sluggish",   ["Pupils react slowly",                  "Equal, sluggishly reactive"]],
            ["pinpoint",   ["Pupils are very small",                "Bilateral miosis, pinpoint"]],
            ["dilated",    ["Pupils are very large",                "Bilateral mydriasis"]],
            ["fixed",      ["Pupils do not react to light",         "Fixed and dilated bilaterally"]],
            ["unequalL",   ["Left pupil is larger",                 "Anisocoria, left blown, right reactive"]],
            ["unequalR",   ["Right pupil is larger",                "Anisocoria, right blown, left reactive"]]
        ]
    };

    // capillary refill.
    case "crt": {
        createHashMapFromArray [
            ["brisk",      ["Color returns immediately",           "Capillary refill under 2 seconds"]],
            ["normal",     ["Color returns quickly",               "Capillary refill 2 seconds"]],
            ["delayed",    ["Color returns slowly",                "Capillary refill 3 to 4 seconds"]],
            ["prolonged",  ["Color takes a long time to return",   "Capillary refill over 4 seconds"]],
            ["absent",     ["Color does not return",               "No capillary refill"]]
        ]
    };

    // positioning.
    // this is the one asked for by name, plus its partners. these are real positions with real names, and the names are
    // how the position gets communicated over a radio.
    case "position": {
        createHashMapFromArray [
            ["elevate30",  ["Elevate Head to 30°",                 "Place in Semi-Fowler's position"]],
            ["lower0",     ["Lower Head to Flat",                   "Place in Supine position"]],
            ["recovery",   ["Recovery Position",                    "Lateral Recumbent"]],
            ["prone",      ["Face Down",                            "Prone"]],
            ["supine",     ["On Their Back",                        "Supine"]],
            ["fowlers",    ["Sitting Up",                           "Fowler's Position"]],
            ["trendel",    ["Head Down, Legs Raised",               "Trendelenburg"]]
        ]
    };

    // breathing.
    case "breathing": {
        createHashMapFromArray [
            ["normal",     ["Breathing normally",                   "Eupneic, equal chest rise"]],
            ["slow",       ["Breathing slowly",                     "Bradypneic"]],
            ["fast",       ["Breathing quickly",                    "Tachypneic"]],
            ["none",       ["Not breathing",                        "Apneic"]],
            ["shallow",    ["Breathing shallowly",                  "Shallow, poor tidal volume"]],
            ["uneven",     ["One side of the chest moves less",     "Asymmetric chest rise"]],
            ["agonal",     ["Occasional gasping",                   "Agonal respirations"]],

            // the two full-sentence findings that overrides/fn_checkBreathingLocal.sqf emits, and their bare log
            // forms. these are the ONLY rows in this file that fn_clinTerm reads, so the clinical wording for the
            // two findings lives here and nowhere else.
            // the left column is ACM's own wording, copied from
            // ACM breathing/stringtable.xml keys CheckBreathing_None, _None_Short, _ShallowRapid and
            // _ShallowRapid_Short. it is here so the row is complete and the self test can assert the split.
            // the live plain path does NOT read it: fn_clinTerm returns "" when the hardcore descriptor setting is
            // off, and the caller then localizes ACM's key directly. so ACM's plain register cannot drift from ACM.
            ["apneic",            ["Patient is not breathing",              "Patient is apneic"]],
            ["apneicShort",       ["None",                                  "Apneic"]],
            ["tachyShallow",      ["Patient breathing is rapid and shallow", "Patient is tachypneic with shallow respirations"]],
            ["tachyShallowShort", ["Rapid and shallow",                      "Tachypneic, shallow respirations"]]
        ]
    };

    default { createHashMap };
};

private _row = _tbl getOrDefault [_key, []];
if ((count _row) < 2) exitWith { _key };
_row select ([0, 1] select _hc)
