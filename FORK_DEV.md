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

## Manual migration phases 11-18: compile-time ownership completed

The remaining ACE physiology, interaction/menu, medication, syringe/transfusion and treatment-engine replacements were moved into their native ACM owners. The old `ACME_native` delegate namespace, duplicate override scaffolding, postInit function reassignments and runtime function-pointer monkey patches were removed. A repository regression test now rejects assignments to `ACM_*_fnc_*`, `ACME_*_fnc_*` or `ace_*_fnc_*` at runtime.

At the end of phase 18, modified ACM/ACE behavior is selected through native addon functions or ACM-owned compile-time ACE overrides. `addons/acm_extended/overrides` contains no runtime SQF replacement layer.

## Phase 19: subsystem initialization split

The first behavior-preserving split of the monolithic Extended postInit moved medication/vial registry repair, training-casualty setup, infusion constants and thoracostomy constants/UI registration into explicit initializers:

- `ACME_fnc_initMedicationRegistry`
- `ACME_fnc_initTrainingCasualty`
- `ACME_fnc_initInfusionConfig`
- `ACME_fnc_initThoracostomyConfig`

Initialization order and behavior remain unchanged.

## Phase 20: configuration-domain initialization split

Six additional startup domains now have explicit owners instead of living inline in the global postInit:

- `ACME_fnc_initCirculationConfig`
- `ACME_fnc_initConsciousnessConfig`
- `ACME_fnc_initIVProcedureConfig`
- `ACME_fnc_initPatientPositioningConfig`
- `ACME_fnc_initMegacodeConfig`
- `ACME_fnc_initDrugPhysiologyConfig`

This is an ownership-only refactor. Existing values, formulas, initialization order, event handlers and per-frame handlers are unchanged. The global Extended postInit is now about 3,221 lines, down from more than 4,000 before the initialization split.

## Phase 21: physiology configuration ownership

Two more physiology domains were separated from the global initializer without changing their values or runtime workers:

- `ACME_fnc_initResuscitationConfig` owns calcium/citrate, overload edema, push-dose and distal-pressor startup tunables.
- `ACME_fnc_initTbiProgressionConfig` owns TBI vital coupling, recovery, autoregulation, ventilation interaction and herniation progression tunables.

The TBI PFHs and event ownership remain outside these configuration helpers. The global Extended postInit is now about 3,004 lines.

## Phase 22: device, menu and procedure configuration ownership

Contiguous startup-only blocks were moved into explicit initializers while runtime handlers stayed at their original call sites:

- `ACME_fnc_initProcedurePainConfig`
- `ACME_fnc_initBlastLungConfig`
- `ACME_fnc_initFlightMotionConfig`
- `ACME_fnc_initVentilatorClinicalConfig`
- `ACME_fnc_initMedicalMenuConfig`
- `ACME_fnc_initVentilatorUiPowerConfig`
- `ACME_fnc_initPerfusionConfig`
- `ACME_fnc_initVentilatorRuntimeConfig`
- `ACME_fnc_initFlightPhysiologyConfig`
- `ACME_fnc_initAirwayProcedureConfig`
- `ACME_fnc_initNarcBoxConfig`

The global Extended postInit is now about 2,585 lines. Event/PFH registrations remain in postInit for the next ownership pass.

## Phase 23: runtime registration ownership begins

The first runtime-registration domains have explicit entry points. Their code was moved intact and each helper is called synchronously at the exact former registration point, preserving CBA handler/PFH order:

- `ACME_fnc_registerTbiRuntime`
- `ACME_fnc_registerBlastLungRuntime`
- `ACME_fnc_registerCirculationRuntime`
- `ACME_fnc_registerVentilatorAudioRuntime`
- `ACME_fnc_initNrbRuntime`

This moves TBI/Cheyne-Stokes ticking, blast-lung wound intake, circulation/acidosis/auto-BP ticking, ventilator audio/alarm runtime and NRB runtime out of the global initializer without changing their behavior. The global Extended postInit is now about 2,276 lines.

## Phase 24: bedside, thermal and visual runtime ownership

Five more contiguous bedside/runtime domains were extracted from the global initializer and are still invoked at their original sequence points:

- `ACME_fnc_initHangBagRuntime` owns Hang Bag/pressure-infuser setup, line geometry and treatment-pose synchronization.
- `ACME_fnc_initHpmkCoreRuntime` owns HPMK rewarming/LifeWarmer coupling and its core thermal tick.
- `ACME_fnc_initAcreBabbleRuntime` owns obtunded ACRE2 speech-pulse configuration and delayed language registration.
- `ACME_fnc_initProcedureEnvironmentConfig` owns laryngoscopy geometry plus procedure darkness, adaptation and cyanosis presentation tunables.
- `ACME_fnc_registerHpmkVisualRuntime` owns HPMK blanket reconciliation, pickup interaction and client visual runtime.

No clinical formula, event/PFH cadence or initialization order changed in this phase. The global Extended postInit is now about 2,025 lines.

## Phase 25: patient-facing runtime ownership

Five additional patient-facing runtime clusters now have explicit subsystem entry points, again called at the exact former registration points:

- `ACME_fnc_registerChestSealPresenceRuntime` owns collaborative chest-seal cursor/tool presence events.
- `ACME_fnc_registerHpmkTransportCleanupRuntime` owns cleanup of legacy network blanket objects during transport.
- `ACME_fnc_initHypothermiaRuntime` owns injury-driven cooling/recovery configuration and the hypothermia tick.
- `ACME_fnc_registerMedicalBodyBaseRuntime` owns the base HPMK, NRB and junctional body-image overlays and junctional GUI reconciliation.
- `ACME_fnc_initBloodStorageRuntime` owns the blood fridge/cooler, cold-chain, clot-pop and loadout-change runtime.

The extraction is behavior-preserving and retains CBA/event/PFH registration order. The global Extended postInit is now about 1,759 lines.

## Phases 26-36: patient, rhythm, monitor and interaction runtime ownership

The remaining large runtime blocks were moved out of the global initializer without changing their registration order. Explicit owners now cover clinical lifecycle/death-reset hooks, head/EJ/ETT presentation, blast-overpressure, junctional/chest-seal configuration, injury presentation, rhythm triggers/hemodynamics, monitor synchronization, obtundation/provider lifecycle, rhythm persistence, infusion processing, EMMA/BVM/AED runtime, treatment/head-elevation/Megacode interactions, minigame interaction bridging, medication delivery acknowledgements, ECG motion-artifact leases and syringe/Narc Box per-life cleanup.

By Phase 36, `ACME_fnc_postInit` had fallen to roughly 821 lines while the zero-runtime-function-pointer-patch contract remained intact.

## Phases 37-39: final postInit runtime extraction

The final inline runtime clusters now have named owners:

- fork/network bootstrap and debug watchdog
- thoracic and medical-menu-open presentation/runtime
- clinical injury-list/access-site/AED presentation
- vesicant/extravasation runtime
- ROSC breathing behavior
- roller-clamp drag runtime
- TBI core state/config bootstrap
- IO/direct-pressure/infusion-pulse/breath-audio integration

After Phase 39, `postInit` contained almost exclusively subsystem calls.

## Phases 40-46: authoritative state-writer boundaries

The fork has started enforcing one mutation endpoint per important mutable state domain rather than allowing unrelated functions to publish the same state directly.

Completed boundaries include:

- Extended IV-bag mutations cross `ACME_fnc_ivBagsCommit`.
- Native chest-injury state is written through breathing-owned `ACM_breathing_fnc_setChestInjuryState`.
- `ACME_tbi_State` is committed only by `ACME_fnc_tbiStateCommit`.
- `ACME_circ_State` is committed only by `ACME_fnc_circStateCommit`.
- Medicated infusion contents and `ACME_infusion_HasBagMedications` are committed together by `ACME_fnc_infusionMedicationStateCommit`.
- Y-line membership and detached-bag custody each have a single mutation gate.
- Native cardiac-arrest target rhythm writes from Extended route through circulation-owned `ACM_circulation_fnc_setCardiacArrestTargetRhythm`, including owner-local publication deduplication.

The infusion medication-state consolidation also fixes a stale-state defect: removal/move paths that deleted the final medicated bag can no longer leave `ACME_infusion_HasBagMedications` stuck true.

## Phase 47: orchestration-only postInit

`ACME_fnc_postInit` is now an orchestration surface only. The last inline assignment (`ACME_net_epsilon`) moved to `ACME_fnc_initNetworkSyncConfig`.

A regression test rejects assignments, direct state writes, event-handler registration, PFH registration or mission-event registration inside `fn_postInit.sqf`. Every executable line in postInit must be an explicit `call ACME_fnc_*;` subsystem/function entry point.

## Phase 48: native IV-bag ownership

The Extended IV-bag mutation gate now delegates its final publication to circulation-owned `ACM_circulation_fnc_setIVBagsState`. Existing `ACME_fnc_ivBagsCommit` remains the Extended interface so callers do not need to know the native storage implementation, but the actual `ACM_circulation_IV_Bags` write now lives in the owning ACM circulation addon.

At this checkpoint all **43 fork phase regression tests** pass, `git diff --check` is clean, and the fork still has zero runtime ACM/ACE/ACME function-pointer monkey patches. Engine/PBO/multiplayer acceptance is still required before release use.


## Phases 49-53: native state-owner boundary completion

The remaining Extended writes into native ACM state have been moved behind owner-addon APIs.

- **Phase 49:** airway collapse, airway obstruction/vomit state, oral adjunct state and airway assessment timestamps now mutate through `addons/airway` owner functions.
- **Phase 50:** target vitals, patient lying state, treatment-state markers and the continuous-action flag now mutate through `addons/core` owner functions.
- **Phase 51:** runtime breathing state (RR/BVM, pneumothorax/tension, chest seal, thoracostomy, hemothorax and lung-state fields) now mutates through `addons/breathing`. High-frequency scalar paths retain owner-local publication deduplication.
- **Phase 52:** circulation/AED/runtime state now mutates through `addons/circulation`. The Phase 48 IV-bag boundary was also tightened so generic `ACME_fnc_setVarNet` callers can no longer bypass `ACME_fnc_ivBagsCommit` / `ACM_circulation_fnc_setIVBagsState`.
- **Phase 53:** the final target-oxygen and CBRN breathing-ability publishers were moved to core/CBRN owner APIs. A repository regression guard now distinguishes legal ACM state reads from illegal ACM state publication.

At this checkpoint `addons/acm_extended` contains **zero direct native `ACM_*` state publications**. Extended still consumes ACM's public variables where required for compatibility, but state changes terminate in the owning native addon. All **48 fork phase regression tests** pass through Phase 53. Engine/PBO/multiplayer acceptance remains required before release use.


## Phases 54-58: ACE integration and Extended state gates

The ownership pass now extends across the ACE integration boundary and back into important Extended-owned physiology/runtime state.

- **Phase 54:** direct Extended writes to ACE patient medical variables were consolidated behind `ACM_core_fnc_setAceMedicalState`. ACE remains canonical storage; the bridge preserves each caller's public/local behavior and the former owner-local scalar deduplication used by high-frequency `ACME_fnc_setVarNet` paths.
- **Phase 55:** chest-seal and thoracostomy procedure displays no longer own ACE medical-menu PFH state. Pause/resume now terminates in `addons/gui` through `ACM_GUI_fnc_pauseMedicalMenuPFH` / `ACM_GUI_fnc_resumeMedicalMenuPFH`.
- **Phase 56:** the last direct `ace_*` publications from `addons/acm_extended` were removed. Drag/carry capability and temporary ACE cursor-menu forcing now terminate in ACM core integration functions. Core now explicitly requires `ace_dragging` and `ace_interact_menu`, making those compile-time integration/override relationships deterministic.
- **Phase 57:** `ACME_rhythm_active` now has one authoritative mutation endpoint, `ACME_fnc_rhythmActiveCommit`. The gate preserves both historical publication contracts: deduplicated rhythm-engine updates and unconditional Megacode/lifecycle publications.
- **Phase 58:** `ACME_hpmk_state` and `ACME_hpmk_on` are committed as one invariant through `ACME_fnc_hpmkStateCommit`. Only `wrapped`/`exposed` states can be actively rewarming; prep/remove/reset transitions cannot leave contradictory HPMK state behind.

At this checkpoint `addons/acm_extended` contains **zero direct native `ACM_*` publications and zero direct `ace_*` publications**. All **53 fork phase regression tests** pass through Phase 58, and a balanced-delimiter scan passes across all **1,463 SQF files**. HEMTT is not installed in the current build environment, so an engine/config/PBO compile and multiplayer acceptance remain required before release use.

## Phases 59-67: persistent physiological state ownership

The single-writer pass now covers the remaining high-value Extended physiological and intervention state, including persistence/rehydration paths.

- **Phase 59:** persistent obtundation state is committed through `ACME_fnc_obtundedStateCommit`. `ACME_obtunded`, manual status and stored posture can no longer drift independently; B49's free-posture behavior remains intact.
- **Phase 60:** `ACME_blastLung_State` now has one writer, `ACME_fnc_blastLungStateCommit`, covering injury, progression/healing and hard reset while preserving direct versus deduplicated publication behavior.
- **Phase 61:** native rhythm persistence kind/held-rhythm state is atomic through `ACME_fnc_rhythmNativeHoldCommit`. An empty hold kind cannot retain a stale held rhythm.
- **Phase 62:** NRB mask, oxygen-source and active-delivery state is committed through `ACME_fnc_nrbStateCommit`. Mask-off implies no oxygen and no active delivery; no oxygen implies no active delivery.
- **Phase 63:** blast-lung ARDS latch state and its pre-latch dwell clock share `ACME_fnc_blastLungArdsCommit`, preventing ordinary threshold-clock changes from silently breaking the latched state.
- **Phase 64:** durable ETT state is committed through `ACME_fnc_ettAirwayStateCommit`. Tube insertion, cuff state and secured/unsecured markers now share one boundary while preserving the valid laryngoscopy case where the cuff is inflated before the tube is finally seated.
- **Phase 65:** active rocuronium paralysis is committed through `ACME_fnc_rocParalysisCommit` across medication ticking, restore and reset.
- **Phase 66:** cumulative calcium-chloride-equivalent credit is updated through `ACME_fnc_calciumCreditCommit`, centralizing the read/modify/write transaction for calcium chloride, calcium gluconate, restore and reset.
- **Phase 67:** clinical serialization restore/reset now recognizes these owner-gated persistent state families instead of reintroducing a hidden generic writer. HPMK, obtundation, blast-lung/ARDS, native rhythm hold and NRB snapshots rehydrate/reset through the same mutation boundaries used at runtime; ETT, rocuronium and calcium continue through their dedicated persistence gates introduced in Phases 64-66.

Validation at this checkpoint is split into two bounded runs because the single all-in-one wrapper exceeds the execution window: **30/30 tests through Phase 35** and **32/32 tests for Phases 36-67** pass, for **62/62 fork phase regression tests** total. A comment/string-aware delimiter scan passes across **1,471 SQF files and 13 `config.cpp` files**. HEMTT is not installed in the current environment, so this remains source/static validation; engine config merge, PBO compilation/signing and multiplayer acceptance are still required before release use.

## Phases 68-70: thermal and disposition state writers

The authoritative-writer pass continues into the remaining cross-system patient physiology/disposition variables without changing their clinical formulas.

- **Phase 68:** patient-level blood thermal presentation state (`ACME_warmedBlood`, `ACME_coldBlood`, `ACME_coldBloodHungAt`, `ACME_tempFlagHoldUntil`) now crosses `ACME_fnc_bloodThermalStateCommit`. Existing per-patient warmed/cold semantics are preserved exactly; this phase only centralizes mutation and persistence.
- **Phase 69:** `ACME_hypo_temp` now crosses `ACME_fnc_hypothermiaTemperatureCommit` for passive cooling, passive self-rewarming, HPMK rewarming, manual hypothermia staging, restore and reset. No cooling/rewarming rate or threshold was changed.
- **Phase 70:** `ACME_requiresEvac` now crosses `ACME_fnc_evacuationRequirementCommit` from TBI, blast-lung, restore and reset paths. This deliberately preserves the existing shared-boolean semantics rather than introducing per-cause reason tracking during an ownership refactor.

Validation remains clean: the previously completed **30/30 tests through Phase 35** plus **35/35 tests for Phases 36-70** pass, for **65/65 fork phase regression tests** total. The structural scanner passes across **1,474 SQF files and 13 `config.cpp` files**. HEMTT remains unavailable in this environment, so engine/config/PBO and multiplayer validation are still pending.

## Phases 71-78: rhythm recovery, ventilator shunt and pharmacologic outcome writers

The authoritative-writer pass now covers several remaining physiologic recovery clocks and rocuronium/medication state families without changing their clinical formulas.

- **Phase 71:** native-rhythm high-HR persistence and post-shock/ROSC grace clocks now cross `ACME_fnc_rhythmNativeHighHRFloorCommit` and `ACME_fnc_rhythmNativeShockGraceCommit`. Threshold observation, rhythm release, shock, ROSC, respawn, restore and reset retain their previous public/local and deduplicated publication behavior.
- **Phase 72:** ventilator-derived pulmonary shunt now crosses `ACME_fnc_ventShuntCommit` from live oxygenation, restore and reset. The existing shunt/recruitment/FiO2 formula and live publication cadence are unchanged.
- **Phase 73:** acute awake-paralysis sympathetic state now crosses `ACME_fnc_rocStressStateCommit`. Post-ROSC grace, awake dwell, peripheral-resistance add and rocuronium HR drive share one boundary; the live tick retains scalar `ACME_fnc_setVarNet` deduplication.
- **Phase 74:** the latched RSI awareness outcome now crosses `ACME_fnc_rocAwarenessStateCommit`. Event status, first-event time and cumulative aware-paralyzed seconds restore/reset together and cannot partially rehydrate.
- **Phase 75:** the derived `ACME_roc_awakeParalysis` flag now crosses `ACME_fnc_rocAwakeParalysisCommit`.
- **Phase 76:** the rocuronium respiratory-muscle apnea flag now crosses `ACME_fnc_rocApneaCommit`.
- **Phase 77:** blast-lung episode metadata now crosses `ACME_fnc_blastLungEpisodeCommit`. Exposure count, first onset and most-recent injury time no longer have separate runtime/persistence writers.
- **Phase 78:** the per-family medication-toxicity generation latch now crosses `ACME_fnc_medicationToxicityFiredCommit`. Naloxone generation stamping and overdose-trigger commits use the same owner, and HashMap replacement copies the supplied snapshot rather than sharing a mutable restore object.

Validation is clean in bounded runs: **30/30 tests through Phase 35** and **43/43 tests for Phases 36-78**, for **73/73 fork phase regression tests** total. A comment/string-aware delimiter scan passes across **1,483 SQF files and 13 `config.cpp` files**, and all Phase 71-78 CfgFunctions registrations resolve to source files. HEMTT remains unavailable in this environment, so engine/config merge, PBO build/signing and multiplayer acceptance are still pending.


## Phase 90: architecture-complete source checkpoint

See `FORK_CHECKPOINT_PHASE90.md`. The ownership refactor is intentionally stopped here. Phase tests 1-90 pass (85 test files total), and whole-tree structural screening passes across 1,495 SQF plus 13 config files. Remaining work is build/runtime validation rather than mechanical writer-gate expansion.

## Phases 91-110: build-readiness and compatibility hardening

The fork has moved from architecture refactoring into build/source compatibility validation. These phases do not reopen the completed authoritative-writer migration and do not change clinical thresholds, medication doses or physiology formulas.

Build-readiness gates now cover PBO-prefix/include closure, internal `CfgPatches` dependencies, exact and dynamic runtime asset paths, source hygiene, path portability, native and Extended function registration/symbol closure, localization uniqueness, preprocessor include cycles, public version identity, supplied ACE API compatibility, and upstream ACM API/class/PBO namespace preservation.

The gates found and corrected concrete source defects on the current Phase 90 line: one duplicate `SurgicalAirway_action` PREP registration, three duplicate airway localization IDs, nine case-sensitive asset path mismatches, and an obsolete ACE weather-function call. The fork-retained ACE blood-volume compatibility function is now documented explicitly.

Validation through Phase 110 is clean in bounded runs: **35/35 tests for Phases 1-40**, **40/40 for Phases 41-80**, and **30/30 for Phases 81-110**, for **105/105 fork phase regression scripts** total. Structural screening passes across **1,495 SQF files and 13 `config.cpp` files**. See `FORK_CHECKPOINT_PHASE110.md` for exact gate counts and corrected defects.

A real HEMTT/PBO build and Arma runtime/multiplayer acceptance remain the next validation layer. Further architecture work should be driven by concrete failures from that layer rather than generic writer wrapping.

## Phases 111-116: ACE load-order and supplied-baseline compatibility hardening

The post-architecture build pass now validates the fork against the exact ACE3/ACM baselines supplied with the project rather than only checking fork-local closure.

- **Phase 111:** compile-time ACE overrides must be ordered after every ACE addon they replace. This found a real load-order defect in `ACM_core`: it overrides functions from 14 ACE components, but `requiredAddons[]` only named five of those target components. `ACM_core` now explicitly requires all 14 override targets, preventing the fork override classes from racing their upstream ACE definitions during addon load.
- **Phase 112:** the 68 compile-time ACE override targets are frozen against the supplied ACE3 source. Sixty-seven still have same-named upstream source targets; `ace_medical_status_fnc_getBloodVolumeChange` remains the one documented fork-retained compatibility owner.
- **Phase 113:** every `ace_*_fnc_*` symbol referenced by active fork source or function-name strings must resolve to the supplied ACE PREP API or a fork-owned compile-time override. The current fork references 73 such symbols.
- **Phase 114:** every ACE patch named by fork `requiredAddons[]`, and every ACE tag used by a compile-time override, must exist in the supplied ACE3 addon baseline. The current fork uses 16 distinct ACE dependency identities.
- **Phase 115:** every one of the 1,068 localization keys supplied by upstream ACM remains present in its original native component stringtable.
- **Phase 116:** the HEMTT project identity is pinned to `mainprefix = "x"` and `prefix = "ACM"`, with the fork root assets included, so existing `\x\ACM\...` public paths cannot silently change during packaging.

Validation remains clean after the load-order repair: **35/35 tests for Phases 1-40**, **40/40 for Phases 41-80**, and **36/36 for Phases 81-116**, for **111/111 fork phase regression scripts** total. Structural screening still passes across **1,495 SQF files and 13 `config.cpp` files**.

The HEMTT Linux release was identified but cannot be staged into this execution sandbox, so the remaining validation boundary is unchanged: an external HEMTT check/build followed by Arma config/PBO, dedicated-server/headless-client, two-provider synchronization and full clinical regression testing.

## Phases 117-120: ACE config-order and native dependency compatibility

The build-readiness pass found one additional config-merge ordering defect and added broader dependency compatibility guards.

- **Phase 117:** `ACM_Extended` now explicitly requires `ace_map` before modifying `CfgVehicles > CAManBase > ACE_SelfActions > ACE_Equipment > ACE_MapFlashlight`. Without that edge, ACE Map could load after Extended and restore the stock flashlight condition, dropping the laryngoscope-light block. The phase gate requires the `ace_map` dependency and the Extended condition override together.
- **Phase 118:** ACE config inheritance is validated against the supplied ACE dependency graph. The fork currently contains **92** `class Child: ACE_*` inheritance uses; every parent class is guaranteed available through the owning addon's direct/transitive ACE dependency closure.
- **Phase 119:** the 12 native ACM addons may add fork-required dependencies but may not drop any direct `requiredAddons[]` entry from the supplied upstream ACM source.
- **Phase 120:** all **12/12** supplied native ACM `CfgPatches` identities remain present in the combined fork, with `ACM_Extended` added as the thirteenth fork patch.

After the Phase 117 load-order repair, the existing Phases 1-80 remain clean and Phases 81-120 pass **40/40**. Combined with the previously rerun **35/35** Phases 1-40 and **40/40** Phases 41-80, the current fork is at **115/115** phase regression scripts passing. Structural screening remains clean across **1,495 SQF files** and **13 `config.cpp` files**.

## Phases 121-127: reported runtime regression repair batch

A user-reported regression pass now sits on top of the Phase 120 build-readiness checkpoint. It corrects Narc Box/preparation list width and removes carousel interpolation cost; fixes patient-local Get Up release when obtundation is disabled; makes ET-tube depth/position persist across Airway View reopen and enforces collar-off/cuff-down extubation; removes direct pressure from ACM's exclusive continuous-action lock and adds an explicit stop action; initializes local chest-hole state before first render and strengthens grounded roll endpoints; reports ventilator-driven breathing from delivered ventilator values; aligns the CBA rocuronium block threshold with the runtime model; and fixes the debug panel's double-application of the ketamine induction threshold.

The ketamine physiology worker itself was already using the correct shared normalized sedation model, so Phase 127 changes debug interpretation only rather than retuning ketamine pharmacology.

Validation through Phase 127 is clean in bounded runs: **35/35** tests for Phases 1-40, **40/40** for Phases 41-80, **30/30** for Phases 81-110 and **17/17** for Phases 111-127, for **122/122** fork phase regression scripts total. Whole-tree structural screening passes across **1,495 SQF files and 13 `config.cpp` files**. See `FORK_CHECKPOINT_PHASE127.md` for the exact fixes and runtime retest matrix.

## Phases 128-132: pressure/vehicle interaction, Hang Bag, fluid registry, ultrawide UI and HPMK transport repairs

The next reported-runtime batch preserves the Phase 127 architecture while repairing five concrete integration families.

- **Phase 128:** Direct pressure retains the explicit Stop action and adds an AED-style distance/vehicle-context leash. Pulse palpation uses a vehicle-safe direct assessment when medic and patient share the same vehicle instead of closing the UI and forcing a ground animation.
- **Phase 129:** Hang Bag uses a local non-physical bag, local rope helpers and the model-free engine rope. It no longer teleports/rotates the provider every tick or repeatedly reasserts the hold animation; cancel retires the held-loop generation before the exit animation.
- **Phase 130:** Extended fluid item/data pairs are reconciled both at startup and when the transfusion inventory is built. The inventory eligibility gate now reads the selected self/patient/vehicle target rather than always inspecting `ACE_player`, restoring reliable Plasma-Lyte visibility.
- **Phase 131:** Native ACM and Extended centered panel UIs now share a height-derived, centered 16:9 maximum-width canvas. LifePak/SYNC, Syringe/Narc Box, Transfusion, Surgical Airway and Extended overlays retain consistent geometry through 21:9 and 32:9; inherited Transfusion body-control axis mistakes were also corrected. Full-screen procedural workspaces deliberately remain full-safe-zone surfaces.
- **Phase 132:** Wrapped HPMK presentation is no longer attached to the casualty at all. A collisionless local simple object mirrors the patient visual transform, removing the final HPMK parent/child transform chain capable of fighting ACE drag/carry/recovery-position physics.

Validation through Phase 132 is clean: **127/127 canonical fork phase tests pass**, and structural screening passes across **1,496 SQF files and 13 `config.cpp` files**. See `FORK_CHECKPOINT_PHASE132.md` for the exact changes and runtime acceptance matrix.

## Phases 133-136: validated IV rope restoration and remote-execution hardening

Phase 133 reverses only Phase 132's model-free Hang Bag rope choice after in-game confirmation that the bundled custom line works correctly. The clear/blood/plasma custom rope classes are restored per Hang Bag session while the local bag/helpers, no-transform-watchdog, 20 Hz tick and clean cancel lifecycle remain intact.

Phases 134-136 harden multiplayer dispatch. Raw remote `say3D`, `forceWalk` and `deleteVehicle` commands were replaced with named fork-owned endpoints, all fork-owned remote function targets are represented in `CfgRemoteExec`, and the whitelist is checked against actual registered functions. The fork contributes named allow entries only and does not set global remote-execution modes.

Validation through Phase 136 is clean: **131/131** fork phase regression scripts pass and structural screening passes across **1,500 SQF files and 13 `config.cpp` files**.

