# ACM Extended Fork Development

Branch: `dev/acm-fork`

This tree combines the supplied upstream ACM source and ACM Extended B92 into one buildable mod package. The goal is to remove ACM as a runtime dependency while preserving ACM's public API for mission/loadout compatibility.

## Runtime dependency target

- CBA
- ACE
- ACM Extended Fork

External Advanced Combat Medicine is **not** required by this source tree because its core addons are included here.

## Compatibility rule

Existing `ACM_*` classes, functions, variables, events and addon names remain intact unless there is a specific reason to migrate them. New Extended-owned systems continue to use `ACME_*`.

## Migration strategy

1. Keep current ACME addon operational inside the fork as a compatibility bridge.
2. Move ACME overrides into the owning ACM addon one subsystem at a time.
3. Delete each runtime override only after its native merged implementation passes regression tests.
4. Convert cross-system direct writes into explicit subsystem interfaces/observers.
5. Finish with ACME as native fork functionality rather than an override layer.

## Initial migration inventory

- ACME override SQFs: **76**
- Direct one-to-one upstream function matches: **37**
- Manual/ACME-specific mappings: **39**

See `tools/fork_override_map.json` for the generated map.

## First ownership rules

- ACE owns the base medical framework and interaction system.
- Native ACM actions remain native until deliberately merged/replaced.
- CPR and BVM remain ACM-owned; Extended may observe physiology but must not own their provider animation lifecycle.
- Physiological variables should move toward one authoritative writer per domain.

## Native merges completed in phase 1

The following former runtime overrides now live directly in their owning ACM addon functions:

- `ACM_GUI_fnc_getBodyPartIVBags`
- `ACM_airway_fnc_getAirwayState`
- `ACM_circulation_fnc_recentAEDShock`

Their old `CfgFunctions` override registrations and duplicate files have been removed from `addons/acm_extended`.

## Native merges completed in phase 2

Cardiac-arrest ownership has moved into the fork-native ACM core/circulation addons:

- `ACM_core_fnc_onCardiacArrest`
- `ACM_circulation_fnc_updateCirculationState`
- `ACM_circulation_fnc_attemptROSC`
- `ACM_circulation_fnc_handleCardiacArrest`
- `ACM_circulation_fnc_handleReversibleCardiacArrest`
- new native helper `ACM_circulation_fnc_roscEligibility`

The previous `ACME_native_fnc_onCardiacArrest` trampoline and `ACME_fnc_roscEligibility` helper were removed. The native circulation state writer now publishes its own state directly instead of depending on `ACME_fnc_setVarNet`.

## Native merges completed in phase 3

Circulation medication-effect ownership has moved into the native circulation addon:

- `ACM_circulation_fnc_getCardiacMedicationEffects`
- `ACM_circulation_fnc_getNauseaMedicationEffects`
- `ACM_circulation_fnc_handleMed_AdenosineLocal`
- `ACM_circulation_fnc_handleMed_AtropineLocal`
- `ACM_circulation_fnc_handleMed_CalciumChlorideLocal`
- `ACM_circulation_fnc_handleMed_DimercaprolLocal`
- `ACM_circulation_fnc_handleOverdose`

The fork still uses Extended medication exposure/owner helpers where those are part of the newer pharmacology model, but the ACM function identities themselves are now owned by the circulation addon instead of being replaced from `acm_extended`.

## Native merges completed in phase 4

IV/IO access state and physical flow are now native circulation functions:

- `ACM_circulation_fnc_getIVFlowRate`
- `ACM_circulation_fnc_setIVLocal`

The Extended 18g/20g flow model, roller-clamp/pressure-infuser behavior, AAJT occlusion, line-generation invalidation, medicated-bag custody, and exact-site IV state are retained in the native implementations.

## Native merges completed in phase 5

The remaining one-to-one circulation action/UI functions are now native:

- `ACM_circulation_fnc_Syringe_Inject`
- `ACM_circulation_fnc_TransfusionMenu_onKeyDown`
- `ACM_circulation_fnc_feelPulse`

This removes the final direct-match circulation overrides. Extended syringe routing, Escape return-to-menu behavior, and the v1.1.0 pulse-check pose/cancel behavior are retained.

## Native merges completed in phase 6

Airway worker ownership has begun moving into the native airway addon:

- `ACM_airway_fnc_handleAirwayObstruction_Vomit`
- `ACM_airway_fnc_handleSuction`

The owner/epoch-safe vomiting worker and ACCUVAC completion behavior are retained without CfgFunctions replacement from `acm_extended`.
