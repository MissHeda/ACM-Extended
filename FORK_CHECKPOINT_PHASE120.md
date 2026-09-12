# ACM Extended Fork Checkpoint — Phase 120

Phase 120 continues the build-readiness line from Phase 116. No physiology, medication, treatment or authoritative-writer behavior is changed in this batch. The work is limited to config load-order correctness and backward-compatibility contracts.

## Phase 117 — ACE Map config ordering

Extended modifies ACE's map flashlight self-interaction entry so the laryngoscope/minigame light state can block switching the ACE map flashlight while the blade light owns illumination.

The modified config path is:

`CfgVehicles > CAManBase > ACE_SelfActions > ACE_Equipment > ACE_MapFlashlight`

The fork previously did not name `ace_map` in `ACM_Extended.requiredAddons[]`. That made the final condition dependent on incidental addon order: if `ace_map` loaded after Extended, ACE's stock `ACE_MapFlashlight.condition` could replace the Extended condition.

`ACM_Extended` now explicitly requires `ace_map`, guaranteeing that the Extended override is applied after the ACE Map definition.

## Phase 118 — ACE config inheritance dependency closure

A frozen dependency graph derived from the supplied ACE3 source is now used to validate ACE config inheritance.

The fork currently contains **92** inheritance sites of the form `class Child: ACE_*` across its addon configs/HPPs. For each site, the test resolves the supplied ACE addon(s) that define the parent and confirms that at least one defining addon is available through the fork addon's direct or transitive ACE `requiredAddons[]` closure.

Current result: **92/92** inheritance sites resolve with valid load order.

## Phase 119 — upstream ACM dependency preservation

The direct `requiredAddons[]` lists from all **12** supplied upstream ACM components are frozen in `tools/upstream_acm_required_addons_manifest.json`.

Native fork addons are allowed to add dependencies required by the merged Extended behavior, but they may not remove an upstream ACM dependency silently.

Current result: all supplied upstream ACM direct dependencies remain present.

## Phase 120 — upstream ACM CfgPatches identity preservation

The supplied native ACM addon identities are frozen in `tools/upstream_acm_cfgpatches_manifest.txt`.

All **12/12** upstream native patch identities remain present inside the combined fork, and `ACM_Extended` remains the additional fork-owned patch.

This complements the existing PBO-prefix, PREP-function and config-class compatibility manifests: missions and mods can continue to depend on the native `ACM_*` patch identities without requiring a second external ACM package.

## Validation

Current bounded validation:

- Phases 1-40: **35/35**
- Phases 41-80: **40/40**
- Phases 81-120: **40/40**
- Total: **115/115 fork regression scripts**

Whole-tree structural scan:

- **1,495 SQF files**
- **13 `config.cpp` files**
- balanced comment/string-aware delimiters: PASS

Compatibility/build gates now include:

- 13 fork addons
- 111 repository-local preprocessor files
- 1,023 ACME function registrations
- 68 tracked compile-time ACE function overrides
- 73 referenced ACE function symbols resolved
- 17 distinct ACE `requiredAddons` identities validated against the supplied ACE baseline
- 92 ACE config inheritance sites load-order validated
- 348/348 upstream ACM PREP symbols preserved
- 163/163 upstream ACM config classes preserved
- 1,068/1,068 upstream ACM localization keys preserved
- 12/12 upstream ACM PBO prefixes preserved
- 12/12 upstream ACM CfgPatches identities preserved
- all upstream ACM direct `requiredAddons[]` entries preserved

## Remaining boundary

The remaining high-value validation is still a real HEMTT/PBO and Arma runtime pass. The HEMTT Linux release can be identified externally but cannot be staged into this sandbox environment, so this checkpoint does not claim successful binary packing or engine execution.

Next external validation remains:

1. `hemtt check`
2. `hemtt build`
3. Arma 3 config/PBO load test
4. single-player clinical smoke test
5. dedicated-server/headless-client test
6. two-provider synchronization regression
7. full ACM Extended v1.1.0 feature regression
