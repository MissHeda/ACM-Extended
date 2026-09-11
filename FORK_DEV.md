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

## Manual migration phase 11: ACE physiology ownership

The remaining low-level ACE physiology replacements are now owned by ACM core's ACE override layer instead of `addons/acm_extended`:

- `ace_medical_status_fnc_getBloodPressure`
- `ace_medical_status_fnc_getBloodVolumeChange`
- `ace_medical_status_fnc_getCardiacOutput`
- `ace_medical_status_fnc_updateWoundBloodLoss`
- `ace_medical_vitals_fnc_handleUnitVitals`
- `ace_medical_vitals_fnc_updateHeartRate`
- `ace_medical_vitals_fnc_updateOxygen`
- `ace_medical_vitals_fnc_updatePeripheralResistance`
- `ace_medical_damage_fnc_woundsHandlerBase`

`getCardiacOutput` now contains the ACE stroke-volume calculation directly plus the Extended true-PEA mechanical-output rule, so the old `ACME_native_fnc_getCardiacOutput` trampoline is gone. Peripheral resistance is likewise registered directly by ACM core and composes native medication/baroreflex adjustment with Extended pressor, TBI, toxicity, flight-G, awake-paralysis and auto-PEEP contributions.

## Manual migration phase 12: interaction and medical-menu ownership

The interaction/UI collision layer is now native to ACM core/GUI:

- `ace_dragging_fnc_canDrag`
- `ace_dragging_fnc_canCarry`
- `ace_medical_gui_fnc_canOpenMenu`
- `ace_medical_treatment_fnc_canTreatCached`
- `ace_medical_gui_fnc_collectActions`
- `ace_medical_gui_fnc_updateActions`
- `ace_dogtags_fnc_getDogtagData`

The medical action collector now runs ACM's native collection logic directly and then applies Extended category/group metadata in the same function; the `ACME_native_fnc_collectActions` trampoline is gone. Dog-tag cache validation is likewise merged into ACM core's native dog-tag generator, removing the second native delegate.

## Manual migration phase 13: medication treatment ownership

The live ACE medication/IV treatment functions now belong to ACM core's ACE override layer:

- `ace_medical_status_fnc_getMedicationCount`
- `ace_medical_treatment_fnc_ivBagLocal`
- `ace_medical_treatment_fnc_medicationLocal`
- `ace_medical_treatment_fnc_onMedicationUsage`
- `ace_medical_treatment_fnc_tourniquetRemove`

Sugammadex still needs the unmodified medication envelope to distinguish total rocuronium exposure from unbound active drug. That baseline calculation is now an explicit `ACME_fnc_medicationCountRaw` helper rather than the old `ACME_native_fnc_getMedicationCount` CfgFunctions delegate.

## Manual migration phase 14: syringe and transfusion UI ownership

The six remaining ACM circulation UI replacements are now native `addons/circulation` functions:

- `ACM_circulation_fnc_Syringe_Draw_Button`
- `ACM_circulation_fnc_Syringe_PrepareFinish`
- `ACM_circulation_fnc_Syringe_GetMedicationList`
- `ACM_circulation_fnc_Syringe_UpdateMedicationList`
- `ACM_circulation_fnc_TransfusionMenu_MoveBag`
- `ACM_circulation_fnc_TransfusionMenu_MoveBag_Cancel`

The old postInit reassignment of the syringe draw/prepare functions has been deleted. Button-type tracking and the successful-draw plunger/reset behavior now execute directly inside the native circulation functions. Transfusion bag movement keeps the Extended owner/epoch dispatch contract directly in ACM circulation.

## Manual migration phase 15: treatment engine ownership

The final file in `addons/acm_extended/overrides` has been removed. `ace_medical_treatment_fnc_treatment` is now owned entirely by ACM core.

To preserve a clean separation between Extended policy/preflight and ACM's original treatment transaction, the original ACM implementation is compiled internally as `ACM_core_fnc_treatmentNative`. The public ACE treatment override applies Extended procedure permissions, cursor-menu deferral, CPR/BVM native-action bypass, provider preflight, head-position normalization and finite gesture policy, then calls the internal ACM transaction directly.

There are now **zero SQF runtime overrides in `addons/acm_extended/overrides`** and the old `ACME_native_fnc_treatment` delegate has been removed.

## Phase 16: override scaffolding removed

The fork no longer relies on duplicate ACME CfgFunctions wrapper classes. The empty `ACME_overwrite_*` / `overwrite_*` registrations and the `ACME_native` delegate namespace have been removed from `addons/acm_extended/config.cpp`.

The last non-directory function redirection, `ACM_circulation_fnc_AED_AdministerShock`, now owns the Extended owner/epoch shock request directly in `addons/circulation`. `ACM_breathing_fnc_getEtCO2` likewise contains ACM's baseline EtCO2 calculation directly plus the Extended ventilator/CPR modifiers, eliminating `ACME_native_fnc_getEtCO2`.

At this checkpoint there are **no ACME runtime CfgFunctions replacements of ACM/ACE functions**. Extended remains a native addon in the fork for new systems/helpers/UI assets, while modified ACM/ACE behavior lives in the owning ACM addon.

## Phase 17: postInit function reassignments eliminated

The remaining six runtime function replacements have been removed from `ACME_fnc_postInit`:

- `ACM_mission_fnc_generatePatient`
- `ACM_evacuation_fnc_canConvert`
- `ACM_airway_fnc_insertAirwayItem`
- `ace_medical_treatment_fnc_addToLog`
- `ace_common_fnc_displayTextStructured`
- `ace_common_fnc_progressBar`

Training-casualty junctional severity is now stamped by the native ACM mission generator itself. Surgical-casualty ceftriaxone gating is part of ACM evacuation's native `canConvert`, and active-seizure adjunct rejection is part of ACM airway's native insertion function.

The three ACE-wide output/action hooks are now compile-time ACM core overrides based on the supplied ACE3 implementations. Medical logging owns EMMA contact tracking plus IV-site/clinical relabeling directly; structured hints own the clinical descriptor and IV-site wording directly; and the ACE progress bar owns Extended's one-handed direct-pressure duration multiplier directly.

The `ACME_orig_*` saved-function delegates and the `ACME_runtimeOverrideStatus` binding probe for these functions have been deleted. ACM core now explicitly depends on `ace_common` so the common-function overrides have deterministic addon ordering.

## Phase 18: zero runtime function-pointer reassignment

The last postInit function-pointer patch was stale medical-menu code that still attempted to replace `ace_medical_gui_fnc_updateActions` from the deleted `acm_extended\\overrides` tree. That installer and its delayed retries have been removed. The medical-menu renderer is now exclusively the native GUI owner at `addons/gui/overrides/fnc_updateActions.sqf`.

A repository-wide regression test now rejects runtime assignments to any `ACM_*_fnc_*`, `ACME_*_fnc_*`, or `ace_*_fnc_*` function pointer. The misleading `ACME_orig_getBloodPressure` alias was also removed; shock/acidosis baseline callers now invoke the explicit `ACME_fnc_bpNative` baseline helper directly.

At this checkpoint the fork has **zero runtime function-pointer monkey patches**. Modified ACM/ACE behavior is selected through native addon functions or compile-time ACM-owned ACE overrides only.

## Phase 19: subsystem initialization split

The monolithic Extended postInit has begun moving toward explicit subsystem ownership. Four behavior-preserving initializers were extracted and are called in the same order from postInit:

- `ACME_fnc_initMedicationRegistry`
- `ACME_fnc_initTrainingCasualty`
- `ACME_fnc_initInfusionConfig`
- `ACME_fnc_initThoracostomyConfig`

Medication/vial registry repair, training-casualty armor watching, infusion/fluid constants, and thoracostomy constants/UI event registration no longer live inline in the global 4,000-line initializer. This first split reduces postInit by roughly 380 lines while retaining identical initialization order and state.
