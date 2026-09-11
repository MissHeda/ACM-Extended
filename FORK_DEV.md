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

## Native merges completed in phases 2-6

Fork-native ownership now includes the cardiac arrest/ROSC transaction, circulation medication effects, IV/IO flow and access state, circulation syringe/pulse UI hooks, and airway vomiting/suction workers. The corresponding `acm_extended` CfgFunctions overrides have been removed. CPR and BVM remain native ACM-owned actions.

## Native merges completed in phase 7

The entire direct-match breathing override cluster is now fork-native under `addons/breathing`: thoracostomy, chest seals, chest examination, NCD, pneumothorax, breathing/lung state, respiration rate, EtCO2, and stethoscope behavior. Their `acm_extended` CfgFunctions replacement entries and duplicate override files have been removed.

## Native merges completed in phase 8

`ACM_core_fnc_getUp` is now fork-native. This completes all **37 direct one-to-one ACM override migrations** identified at fork start. Remaining files in `addons/acm_extended/overrides` are manual mappings, ACE overrides, or genuinely Extended-specific behaviors that require architectural decisions rather than mechanical relocation.

## Manual migration phase 9: rhythm and monitor ownership

The first manual-map cluster is now native:

- `ACM_circulation_fnc_AED_AnalyzeRhythm`
- `ACM_circulation_fnc_AED_Button_Shock`
- `ACM_circulation_fnc_displayAEDMonitor_generateEKG`
- `ACM_circulation_fnc_displayAEDMonitor_generatePO`
- `ACM_circulation_fnc_displayAEDMonitor_generateCO`
- ACM core's `ace_medical_treatment_fnc_checkPulseLocal` override

This keeps torsades/pVT shock eligibility, custom rhythm waveforms, true-PEA presentation, AAJT pulse occlusion, and clinical pulse wording in their native owners instead of `acm_extended` CfgFunctions replacements.

## Manual migration phase 10: patient lifecycle ownership

Patient lifecycle and persistence are now owned by ACM core again:

- `ACM_core_fnc_resetVariables`
- `ACM_core_fnc_onUnconscious`
- ACM core's ACE override for `ace_medical_fnc_serializeState`
- ACM core's ACE override for `ace_medical_fnc_deserializeState`
- ACM core's ACE medical-feedback `handleEffects` override

The Extended clinical epoch/state serialization, restore guards, spawn/get-up safety, and rhythm pain contribution remain intact without a second `acm_extended` CfgFunctions replacement layer.
