// apply a NAR AAJT-s. the placement location is derived from the ACE selection the action was used on.
// body gives the inguinal placement, which clamps the aorta. it controls both leg, inguinal, junctional wounds and
// acts as a tourniquet on the legs that actually have an inguinal junctional wound. it is a real ACE tourniquet,
// so ACE wounds and iv flow on that leg respond exactly like a normal tq and a second manual tq is auto-blocked
// there. a leg with no inguinal wound is not tourniqueted.
// LeftArm gives the left axilla placement, which controls the left arm, axillary, junctional wound only, with no
// tourniquet.
// RightArm gives the right axilla placement, which controls the right arm junctional wound only, with no
// tourniquet.
// the junctional-bleed pfh reads the placement flags every tick, so a controlled part simply stops draining.
// _this is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
// the application finished, so lift the during-application junctional-bleed pause. the placement flags set below
// take over control from here.
_patient setVariable ["ACME_Junc_AAJTApplying", -1, true];
private _p = toLower _bodyPart;

// record the in-game time of application, as hh:mm:ss. the overview entry shows it, tccc-style, so the team can
// track how long the device has been on. it is stored as a string so it never drifts.
private _two = { private _n = floor _this; if (_n < 10) then {"0" + str _n} else {str _n} };
private _d  = daytime;
private _hh = floor _d;
private _mm = (_d - _hh) * 60;
private _ss = (_mm - (floor _mm)) * 60;
private _atStr = format ["%1:%2:%3", _hh call _two, _mm call _two, _ss call _two];

switch (_p) do {
    // inguinal, meaning aortic and bilateral groin.
    // it is applied on either leg. the AAJT-s clamps the aorta, so both legs get the effects of a real tourniquet, with
    // ACE wound bleeding stopped and the iv and io flow blocked on both legs, rather than only a wounded leg. the
    // tourniquet display, the body-image icon and the "Tourniquet" entry in the injury list, is suppressed for these
    // legs by fn_aajttqhideimage and fn_aajttqhideinjury, because the AAJT-s row is the tourniquet indicator.
    case "leftleg";
    case "rightleg": {
        [_patient, "inguinal", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "leftleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient, "rightleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient, "legs", ["leftleg", "rightleg"]] call ACME_fnc_aajtStateCommit;
        // an aortic clamp leaves no blood in either leg, so the casualty cannot stand on them. the watcher puts
        // them back on the ground if they try, in the same way obtundation in prone does.
        [_patient] call ACME_fnc_aajtDownedTick;
        ["AAJT-S applied: inguinal.", 3] call ace_common_fnc_displayTextStructured;
    };
    // the left axilla.
    case "leftarm": {
        [_patient, "leftarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        ["AAJT-S applied: left axilla.", 3] call ace_common_fnc_displayTextStructured;
    };
    // the right axilla.
    case "rightarm": {
        [_patient, "rightarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        ["AAJT-S applied: right axilla.", 3] call ace_common_fnc_displayTextStructured;
    };
    default {};
};

// record the completed intervention in the activity log of the patient.
private _site = switch (_p) do {
    case "leftleg"; case "rightleg": { "inguinal" };
    case "leftarm": { "left axilla" };
    case "rightarm": { "right axilla" };
    default { _p };
};
[_patient, "activity", "%1 applied an AAJT-S (%2)", [[_medic, false, true] call ace_common_fnc_getName, _site]] call ace_medical_treatment_fnc_addToLog;
