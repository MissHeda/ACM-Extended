// vesicant handling is route limited. it never adds limb damage, bleeding, ACE trauma or necrosis.
// peripheral limb IVs and ej access can develop bruising and local pain that ramps while the exposure lasts.
// the mod ignores upper iv sites and io access, so the medication works normally. calcium gluconate is not a
// vesicant.
ACME_vesicant_enabled = true;
ACME_vesicant_windowSec = 900;
ACME_vesicant_activeWindowSec = 20;
ACME_vesicant_stopResetSec = 30;
ACME_vesicant_extensiveDoseMult = 2.0;
ACME_vesicant_moderateExposureSec = 120;
ACME_vesicant_extensiveExposureSec = 300;
ACME_vesicant_painEnabled = true;
ACME_vesicant_painRampPerSec = 0.0035;
ACME_vesicant_painMild = 0.08;
ACME_vesicant_painModerate = 0.18;
ACME_vesicant_painExtensive = 0.35;
ACME_vesicant_painMax = 0.45;
// recovery. the tissue heals once the infusion stops. there is no treatment, so time and elevation are the
// only tools. after the drug stops, with no dose inside stopresetsec, the exposure recovers. mild extravasation,
// at or below mildresolvestage, resolves fully and the bruise clears. severe extravasation leaves a permanent
// stage floor, which is lasting tissue injury. elevation of the head of bed or the limb, and a wrapped bruise
// through the ACM wrap, both speed it.
ACME_vesicant_recoverPerMin      = 0.5;  // stage fraction healed per minute once recovery starts. a stage clears in about 2 min at baseline.
ACME_vesicant_recoverStartSec    = 30;  // seconds after the last dose before recovery begins. it matches the feel of stopresetsec.
ACME_vesicant_mildResolveStage   = 1;  // an exposure that never exceeded this stage resolves fully. the bruise clears and the floor is 0.
ACME_vesicant_severeFloorStage   = 2;  // an exposure that reached this stage or higher leaves a permanent floor at stage minus 1.
ACME_vesicant_elevateRecoverMult = 1.6;  // elevation (limb up) speeds recovery
ACME_vesicant_wrapRecoverMult    = 1.4;  // a wrapped bruise (ACM wrap) speeds recovery
ACME_vesicant_recoverPainFade    = 0.06;  // pain/min faded while recovering
ACME_vesicant_antidoteWindowSec  = 90;  // seconds after an antidote dose that its reversal boost applies.
ACME_vesicant_antidoteRecoverMult= 3.0;  // the matching antidote multiplies the recovery rate. elevation and a wrap stack on top.
// vesicant and extravasation table. this holds every extravasation-relevant medication in ACM and in this
// addon, including the premixed bags esmolol, magnesium, HTS and mannitol. each row is:
// [classname, pushthreshold, painscale, tier, antidote, bruisefromstage, infusionthreshmult]
// pushthreshold       cumulative dose in mg or ml equivalent at which a push crosses stage 0. lower is more vesicant.
// painscale           multiplier on the local pain the exposure produces.
// tier                "vesicant" for a true tissue vesicant with full staged bruising 0 to 3, or "irritant" for
//                     a pain-forward agent that bruises at higher stages only.
// antidote            "phentolamine" for the catecholamine vasopressors, or "hyaluronidase" for the hyperosmolar
//                     and other agents.
// bruisefromstage     the lowest injury stage that shows a bruise wound. an irritant starts to bruise later.
// infusionthreshmult  multiplier on the threshold when the dose arrives through an infusion, diluted in saline,
//                     rather than a concentrated push. above 1 makes a drip far less injurious than the same
//                     dose pushed neat.
// the table lists both the base classname and the "_IV" delivery variant, because a push and an infusion emit
// different ones.
ACME_vesicant_table = [
    // true vesicants, the calcium salts. chloride is the classic severe vesicant. gluconate is the
    // peripheral-safe salt, which is why it exists, so it injures only at an extreme push dose and much less on
    // a drip.
    ["CalciumChloride_IV",   500,   1.00, "vesicant", "hyaluronidase", 0, 3.0],
    ["CalciumChloride",      500,   1.00, "vesicant", "hyaluronidase", 0, 3.0],
    ["CalciumChlorideLocal", 500,   1.00, "vesicant", "hyaluronidase", 0, 3.0],
    ["CalciumGluconate_IV",  3000,  0.70, "vesicant", "hyaluronidase", 1, 6.0],
    ["CalciumGluconate",     3000,  0.70, "vesicant", "hyaluronidase", 1, 6.0],
    // vasopressors cause ischemic necrosis. phentolamine is the correct antidote. the threshold is very low
    // because they are potent.
    ["Norepinephrine_IV",    0.5,   0.90, "vesicant", "phentolamine",  0, 4.0],
    ["Norepinephrine",       0.5,   0.90, "vesicant", "phentolamine",  0, 4.0],
    ["Epinephrine_IV",       0.5,   0.85, "vesicant", "phentolamine",  0, 4.0],
    ["Epinephrine",          0.5,   0.85, "vesicant", "phentolamine",  0, 4.0],
    // hyperosmolar agents, hypertonic saline and mannitol. both are true tissue vesicants when they extravasate.
    ["HTS3_IV",              120,   0.85, "vesicant", "hyaluronidase", 0, 4.0],
    ["HTS3",                 120,   0.85, "vesicant", "hyaluronidase", 0, 4.0],
    ["Mannitol_IV",          5000,  0.80, "vesicant", "hyaluronidase", 0, 4.0],
    ["Mannitol",             5000,  0.80, "vesicant", "hyaluronidase", 0, 4.0],
    // irritants are pain-forward. they bruise at higher doses only, and go extensive at very high dose. the
    // antidote is hyaluronidase.
    ["Amiodarone_IV",        150,   0.75, "irritant",  "hyaluronidase", 2, 4.0],
    ["Amiodarone",           150,   0.75, "irritant",  "hyaluronidase", 2, 4.0],
    ["AmiodaroneLocal",      150,   0.75, "irritant",  "hyaluronidase", 2, 4.0],
    ["Magnesium_IV",         2000,  0.70, "irritant",  "hyaluronidase", 2, 5.0],
    ["Magnesium",            2000,  0.70, "irritant",  "hyaluronidase", 2, 5.0],
    ["Esmolol_IV",           2500,  0.70, "irritant",  "hyaluronidase", 2, 5.0],
    ["Esmolol",              2500,  0.70, "irritant",  "hyaluronidase", 2, 5.0]
];
ACME_vesicant_patients = [];

["ACM_circulation_handleMedicationEffects", {
    params ["_patient", "_bodyPart", "_classname", ["_dose", 0], ["_viaIV", objNull]];
    if (isNull _patient || {!local _patient}) exitWith {};

    // Actual systemic IV/IO boluses only. Infusion delivery already has its own rate-driven effect.
    if (_classname == "Epinephrine_IV" && {_viaIV isEqualTo true} && {!(missionNamespace getVariable ["ACME_vesicant_infusionDelivery", false])}) then {
        [_patient, _dose] call ACME_fnc_epinephrineBolusLocal;
    };

    // a flush, or the pulses of a continuous infusion. this is what lets calcium gluconate fix citrate-related
    // hypocalcemia, instead of showing as an inert medication adjustment.
    [_patient, _classname, _dose] call ACME_fnc_applyCalciumCredit;

    // B14: tissue injury is settled before systemic admission by medicationLeak.
    // A systemic event has no leaked mass and must never inspect another catheter.
}] call CBA_fnc_addEventHandler;
[{ call ACME_fnc_vesicantTick; }, 2, []] call CBA_fnc_addPerFrameHandler;
