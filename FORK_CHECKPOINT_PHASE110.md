# ACM Extended Fork Checkpoint — Phase 110

Phase 110 is the first post-architecture build-readiness checkpoint for the current `dev/acm-fork` line. It continues directly from the Phase 90 architecture-complete checkpoint and deliberately avoids reopening the finished state-writer refactor.

## Phases 91-110

- Phase 91: adds an offline repository-local build/preprocessor gate covering addon PBO prefixes, local include closure, registered Extended functions and direct preprocessing paths.
- Phase 92: adds `tools/validate_fork.py` as the canonical fork validation entry point, with numeric phase discovery, structural screening and optional HEMTT `check` / `build` execution when HEMTT is available.
- Phase 93: validates the internal `CfgPatches` dependency graph, including closure, load order and acyclicity.
- Phase 94: validates exact case-sensitive project-local rooted runtime paths; only the intentionally optional QEDaveMergens font fallbacks remain absent.
- Phase 95: makes the validator discover the latest phase automatically so new gates cannot be silently omitted.
- Phase 96: validates dynamically formatted local asset families.
- Phase 97: rejects build junk and accidental archive/cache files under `addons`.
- Phase 98: rejects case-folding and Unicode-normalization path collisions.
- Phase 99: validates native PREP/CfgFunctions registration closure and uniqueness. This caught and removed a duplicate `PREP(SurgicalAirway_action)` registration.
- Phase 100: validates ACM/ACME localization ownership and direct-key closure. Three duplicate airway `AirwayIsClear` IDs were removed from Extended; the native airway table now owns the English wording `Airway is patent` while retaining its existing translations.
- Phase 101: validates the local preprocessor include graph for closure, duplicate direct includes and cycles.
- Phase 102: validates `ACME_fnc_*` symbol closure against registered Extended functions.
- Phase 103: validates referenced native `ACM_<component>_fnc_*` symbols against native registrations.
- Phase 104: validates active `QPATHTOF` / `PATHTOF` file references case-exactly. Nine inherited case mismatches were corrected across oxygen-tank/PocketBVM, IV/IO, field-blood-kit and SAM-splint assets.
- Phase 105: locks the public/runtime/debug version identity to **v1.1.0** while retaining **B92** as the internal build stamp.
- Phase 106: updates ambient-temperature integration to the supplied ACE3 weather API `ace_weather_fnc_calculateTemperatureAtHeight`, passing nonnegative ASL altitude as a scalar.
- Phase 107: documents the fork-retained `ace_medical_status_fnc_getBloodVolumeChange` compatibility owner. The supplied ACE3 baseline no longer carries a same-named source target, but ACM/ACME still owns the IV/transfusion volume transaction through that public symbol.
- Phase 108: freezes the supplied upstream ACM PREP API as a compatibility manifest. All **348** upstream PREP symbols remain present; the fork exposes **369** native PREP symbols total.
- Phase 109: freezes directly declared upstream `ACM_*` config classes as a compatibility manifest. All **163** upstream classes remain present; the fork directly declares **305** ACM-prefixed classes total.
- Phase 110: freezes the **12** upstream ACM native `$PBOPREFIX$` namespaces exactly while Extended retains its separate `acm_extended` prefix.

## Source defects corrected during build-readiness validation

1. Removed the duplicate native `PREP(SurgicalAirway_action)` registration.
2. Removed three duplicate airway localization IDs from `acm_extended` and moved the desired English `Airway is patent` wording into the native airway-owned keys.
3. Corrected nine case-sensitive asset references so Linux/HEMTT packaging resolves the actual files exactly.
4. Replaced the obsolete `ace_weather_fnc_calculateTemperature` probe with `ace_weather_fnc_calculateTemperatureAtHeight`, matching the supplied ACE3 source.
5. Documented the intentionally fork-owned ACE blood-volume compatibility function instead of leaving it indistinguishable from a stale upstream override.

## Validation

- **105/105 fork phase regression scripts pass** through Phase 110.
  - Phases 1-40: **35/35**
  - Phases 41-80: **40/40**
  - Phases 81-110: **30/30**
- Structural screening passes across **1,495 SQF files** and **13 `config.cpp` files**.
- Offline build gate: **13 addons**, **111 local preprocessor files**, **1,023 registered ACME functions**.
- Internal dependency gate: **13 patches**, **11 internal ACM edges**, acyclic.
- Exact rooted runtime path gate: **2,868 exact references**, with only two guarded optional missing font paths.
- Dynamic asset gate: **30 references across 22 templates**.
- Native registration gate: **370 PREP registrations** and **68 explicit CfgFunctions sources** resolve uniquely.
- Localization gate: **12 stringtables**, **1,075 unique ACM/ACME keys**, **50 direct localization references**.
- Preprocessor graph: **111 nodes**, **123 local edges**, no cycles.
- Asset macro gate: **258 exact active file references**; three unused path defines are skipped.

## Remaining validation boundary

This checkpoint materially strengthens source/build readiness, but it is not an Arma runtime clearance. HEMTT is not installed in the execution environment and the environment cannot stage the external release binary, so `hemtt check` / `hemtt build`, PBO packing/signing, Arma engine config merge, dedicated-server/headless-client behavior and multiplayer acceptance remain the next validation layer.

Further fork work should now be driven by HEMTT or Arma runtime defects, not by resuming generic state-writer wrapping.
