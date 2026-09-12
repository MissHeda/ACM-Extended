# ACM Extended Fork Checkpoint — Phase 116

Phase 116 continues the Phase 110 build-readiness line without reopening the completed ownership architecture. This batch adds supplied-ACE/ACM compatibility contracts and fixes a concrete ACE override load-order defect.

## Phase 111 — ACE override load order

`addons/core/CfgFunctions.hpp` owns compile-time overrides for 14 ACE component namespaces, but `addons/core/config.cpp` previously ordered `ACM_core` after only five of those target addons. That left several override definitions dependent on incidental addon ordering.

`ACM_core.requiredAddons[]` now explicitly includes every ACE component it overrides:

- `ace_advanced_fatigue`
- `ace_common`
- `ace_dogtags`
- `ace_dragging`
- `ace_interact_menu`
- `ace_medical`
- `ace_medical_ai`
- `ace_medical_damage`
- `ace_medical_engine`
- `ace_medical_feedback`
- `ace_medical_statemachine`
- `ace_medical_status`
- `ace_medical_treatment`
- `ace_medical_vitals`

`ace_main` remains the base ACE dependency. `ACM_gui` already explicitly requires its own override target, `ace_medical_gui`.

The new Phase 111 gate derives ACE override tags from fork `CfgFunctions.hpp` and requires each target addon to appear in the owning fork addon's `requiredAddons[]`.

## Phase 112 — ACE override target baseline

The fork currently owns **68 compile-time ACE function overrides** across `ACM_core` and `ACM_gui`.

Against the supplied ACE3 source:

- **67/68** targets still have the same upstream source function.
- The only absent upstream target is `ace_medical_status_fnc_getBloodVolumeChange`, which is intentionally retained by the fork as the ACM/ACME IV/transfusion volume-transaction compatibility owner.

The target set and upstream source-path status are frozen in `tools/ace_override_target_manifest.json`.

## Phase 113 — ACE function-symbol closure

A frozen manifest of the supplied ACE3 PREP API is now used to validate every active `ace_*_fnc_*` token referenced by fork source, including function-name strings after comments are stripped.

Current result:

- **73 referenced ACE function symbols**
- every symbol resolves to the supplied ACE PREP API or one of the fork's compile-time ACE overrides
- no unresolved ACE function token remains

## Phase 114 — ACE CfgPatches dependency contract

The supplied ACE3 addon identities are frozen in `tools/ace_cfgpatches_manifest.txt`.

Every ACE name used by fork `requiredAddons[]`, plus every ACE namespace used by a fork compile-time override, must exist in that supplied baseline.

Current result: **16 distinct ACE required-addon identities** resolve successfully, and every override tag maps to a supplied ACE addon.

## Phase 115 — upstream ACM localization preservation

The supplied upstream ACM stringtables contain **1,068 localization keys** across the native components. Their component/key ownership is frozen in `tools/upstream_acm_stringtable_manifest.json`.

All **1,068/1,068** keys remain present in their original native fork component. This preserves mission/UI compatibility while still allowing fork-specific wording changes or additional Extended keys.

## Phase 116 — HEMTT project identity

The HEMTT project is now guarded as part of the compatibility contract:

- `name = "ACM Extended"`
- `author = "mavis"`
- `mainprefix = "x"`
- `prefix = "ACM"`
- root package includes `mod.cpp`, `logo.paa`, and `logo_small.paa`
- Git hash suffixing remains disabled

The `x/ACM` identity is critical because native ACM public paths remain `\x\ACM\addons\...` inside the fork.

## Validation

Bounded full-suite validation after these changes:

- Phases 1-40: **35/35**
- Phases 41-80: **40/40**
- Phases 81-116: **36/36**
- Total: **111/111 fork regression scripts**

Whole-tree structural scan:

- **1,495 SQF files**
- **13 `config.cpp` files**
- balanced comment/string-aware delimiters: PASS

Relevant build/compatibility counts still pass:

- 13 fork addons
- 111 repository-local preprocessor files
- 1,023 ACME CfgFunctions registrations
- 348/348 upstream ACM PREP symbols preserved
- 163/163 upstream ACM config classes preserved
- 12/12 upstream ACM native PBO prefixes preserved
- 1,068/1,068 upstream ACM localization keys preserved
- 68 ACE compile-time overrides tracked
- 73 referenced ACE function symbols resolved

## Remaining boundary

A real HEMTT binary still cannot be staged in this execution sandbox. Phase 116 therefore does **not** claim a successful PBO build or Arma runtime result.

Next external validation remains:

1. `hemtt check`
2. `hemtt build`
3. Arma 3 config/PBO load test
4. single-player clinical smoke test
5. dedicated-server and headless-client test
6. two-provider synchronization regression
7. full v1.1.0 ACM Extended feature regression

Further source changes should be driven by concrete build/runtime failures or specific feature work rather than another broad ownership rewrite.
