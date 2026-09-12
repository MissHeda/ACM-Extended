/*
 * Phase 25 subsystem ownership: Hypothermia injury-cooling, recovery tunables and thermal tick registration.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

// hypothermia auto-triggers. these are injury-driven, cool only, and the HPMK still owns rewarming.
// hemorrhage and cold-product transfusion drive the cold load. the ambient temperature is only a multiplier on
// that injury load. a cold map accelerates the cooling of a casualty, and ambient alone never cools a healthy,
// uninjured unit. fn_ambienttemp resolves the temperature on any map. it takes the mission override,
// ACME_ambientTempC, first, then ACE weather, then a heuristic.
ACME_hypo_coolTickSec     = 5;  // cooling tick interval (s)
ACME_hypo_coolRatePerMin  = 0.5;  // deg c / min the core slides toward its cold target
ACME_hypo_floorC          = 28;  // auto-cooling bottoms at severe (debug can still go lower)
ACME_hypo_bloodNormal     = 6;  // l, full blood volume reference
ACME_hypo_lossStartL      = 0.8;  // cumulative blood loss (l) where cooling begins  (primary)
ACME_hypo_lossFullL       = 2.5;  // cumulative loss (l) at which the loss cold-pull saturates
ACME_hypo_lossMaxDrop     = 6;  // max deg c target drop from hemorrhage
ACME_hypo_txStartL        = 1.0;  // transfused volume in l where cold-product cooling begins. this is secondary.
ACME_hypo_txFullL         = 3.0;  // transfused volume (l) at which it saturates
ACME_hypo_txMaxDrop       = 3;  // max deg c target drop from massive transfusion
ACME_hypo_ambientColdC    = -10;  // ambient at which the cold multiplier peaks
ACME_hypo_ambientWarmC    = 30;  // ambient at which the multiplier bottoms out
ACME_hypo_ambientMaxMult  = 1.6;  // freezing field: injury cooling x1.6
ACME_hypo_ambientMinMult  = 0.75;  // hot field. injury cooling runs at 0.75x and never zero, because trauma cools even in the warm.

// cold-load recovery. hypothermia can resolve once a medic controls the driver.
// the cumulative cold load, ACME_hypo_cumLoss, used to be a one-way accumulator. even after the bleeding
// stopped and the patient rewarmed, the cold target stayed low and they cooled straight back down the moment an
// HPMK came off. now, while the patient is not bleeding and is perfusing, with a MAP above the floor, the body
// re-establishes thermogenesis and the cold load decays. the target drifts back to normal, so the rewarming
// holds. active HPMK rewarming accelerates it. while they still bleed, the load keeps accumulating and the
// hypothermia persists, as it should.
ACME_hypo_recoverPerMin     = 0.35;  // l of cold-load cumloss cleared per minute while recovering. a moderate load, about 1.75 l across the 0.8 to 2.5 band, clears in about 5 min, which matches the target window.
ACME_hypo_recoverBleedMax   = 0.00002;  // l/s of blood loss at or below which bleeding counts as controlled, from ACE getbloodloss. above this there is no recovery, because the casualty still hemorrhages.
ACME_hypo_recoverMinMAP     = 55;  // the MAP in mmhg at or above which perfusion supports self-rewarming. below this they are too hypotensive to recover on their own.
ACME_hypo_recoverHPMKmult   = 2.0;  // multiplier on the cold-load decay while an HPMK is on. active rewarming clears the thermal debt faster than passive recovery.
// severe-hypothermia floor. below this the body cannot self-rewarm, so the cold-load recovery is gated off. a
// severely cold casualty must be actively rewarmed with an HPMK, and control of the bleed alone will not bring
// them back.
ACME_hypo_selfRecoverFloorC = 30;  // deg c. at or below this there is no passive recovery, so active rewarming is mandatory.
ACME_hypo_selfRewarmPerMin  = 0.15;  // deg c/min that a controlled, perfusing, unwrapped casualty passively rewarms. it is slower than the HPMK's 0.6, and it is the body making its own heat once it no longer hemorrhages.
// heuristic ambient model. it is used only when there is no mission override and no ACE weather.
ACME_ambient_baseC          = 20;
ACME_ambient_overcastDrop   = 5;
ACME_ambient_rainDrop       = 4;
ACME_ambient_fogDrop        = 2;
ACME_ambient_nightDrop      = 8;
ACME_ambient_lapsePer1000m  = 6.5;
[{call ACME_fnc_hypothermiaTick}, ACME_hypo_coolTickSec, []] call CBA_fnc_addPerFrameHandler;
