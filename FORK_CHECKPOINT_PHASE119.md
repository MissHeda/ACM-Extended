# ACM Extended Fork Checkpoint — Phase 119

Phase 119 is the current source/build-readiness checkpoint. The useful authoritative-writer migration remains complete; Phases 102-119 add deterministic source, asset, preprocessing and backward-compatibility gates rather than new clinical behavior.

## New guarantees since Phase 101

- Internal `CfgPatches` dependency closure and acyclic load order.
- Exact rooted runtime-file and dynamic asset-family resolution.
- Automatic latest-phase discovery in the unified validator.
- Addon source hygiene and case/Unicode path portability.
- Native PREP/CfgFunctions registration closure and uniqueness.
- Localization key uniqueness and direct-reference closure.
- Local preprocessor include closure with no cycles.
- ACME and native ACM function-symbol closure.
- Case-exact `QPATHTOF`/`PATHTOF` asset resolution.
- Public/runtime/debug version identity pinned to **v1.1.0** with B92 remaining internal only.
- Current ACE weather API compatibility.
- Explicit documentation of the fork-retained `ace_medical_status_fnc_getBloodVolumeChange` compatibility owner.
- Preservation manifests for all upstream ACM PREP functions, direct `ACM_*` config classes and native PBO prefixes.

## Compatibility results

Against the supplied upstream ACM source:

- **348/348** upstream ACM PREP function symbols are preserved.
- **163/163** directly declared upstream `ACM_*` config classes are preserved.
- **12/12** native ACM `$PBOPREFIX$` namespaces are preserved exactly.
- The fork adds 21 native PREP functions and currently exposes 369 native PREP symbols total.

Against the supplied ACE3 source:

- Every ACE addon named in fork `requiredAddons[]` exists in the baseline.
- Every direct ACE function reference resolves to the supplied ACE API or a fork-owned compile-time override.
- **65/66** documented ACE override source targets still exist upstream.
- The one absent target, `ace_medical_status_fnc_getBloodVolumeChange`, is intentionally retained by the fork as the ACM/ACME IV/transfusion volume transaction owner.
- Ambient-temperature integration now uses `ace_weather_fnc_calculateTemperatureAtHeight` rather than the obsolete weather function name.

## Validation

Bounded full-suite validation passes:

- Phases 1-40: **35/35**
- Phases 41-80: **40/40**
- Phases 81-105: **25/25**
- Phases 106-119: **14/14**
- Total: **114/114** fork phase regression scripts

Whole-tree structural screening passes across **1,504 SQF files and 13 `config.cpp` files**.

The Phase 100 offline build gate continues to pass for **13 addons, 111 repository-local preprocessor files and 1,032 ACME CfgFunctions registrations**.

## Source checkpoint

Canonical full-source ZIP SHA-256:

`f26e17cf73654151905e97d0c9b3022b73c899c97087adbbda1f01d2fca7cb49`

ZIP integrity check: clean, **5,292 entries**, no corrupt member.

## Important validation boundary

This checkpoint is not yet a claim of a successful Arma build. HEMTT/PBO tooling is not installed in the current execution environment, and the container cannot stage the public HEMTT Linux release binary. Before release use the fork still requires:

1. `hemtt check`
2. `hemtt build`
3. PBO/config-merge load test in Arma 3
4. single-player clinical smoke testing
5. dedicated-server and headless-client testing
6. two-provider synchronization regression
7. full v1.1.0 ACME feature regression

No additional broad state-writer refactor should be performed unless those runtime tests reveal a concrete ownership defect.
