# Historical backlog, batch 8: stored-syringe and patient identity

## Scope and provenance

Starting commit: `f5f2c3b436a3462103256f78596df1fcf9653d7d`, complete tree `651f8f5e256daf38c1c7e87c2a27fe3a4ff9725a`. GitHub main matched the user's reported Batch 7 checkout. The complete local source and assets were reconstructed from the pinned archives and published patches and matched that exact tree before editing.

This is a **test and documentation update only**. No runtime SQF, configuration, assets, medication dose/concentration, kinetics, sedation/seizure thresholds, blood-flow rule, animation timing, UI layout, inventory policy or network worker changes. The examined implementations did not require a production correction to satisfy the verified contracts. Earlier fixes are preserved, not reconstructed or retuned.

## Resolved historical outcomes

Nine original source-contract identities now pass: **H221, H222, H226, H229, H235, H242, H245, H413 and H414**. The original unresolved source-contract subset decreases from **187 to 178**. Across the original 448 failing outcomes, **246 now pass and 202 remain failing**. The original seven collection and five setup errors remain separately tracked as resolved in the complete 460-outcome ledger.

These are nine historical test outcomes, not nine distinct gameplay defects. Three repeat the personal-kit lifecycle requirement. The original methods/identities are retained, and only the nine intended bodies in four existing test modules change. Their former failures depended on obsolete inline writes, a retired index-based menu handoff, a replaced Body Map preview, a staging-only Draw path or an old dogtag delegate name.

## What the new execution coverage establishes

### Stable syringe identity

Actual `skStoreEnsureIds`, `skSelectStored`, `skSelectedIndex`, `skAfterStoredRemoval`, `skOpenStoredSyringe` and self-menu callbacks run in SQF-VM. Tests check legacy row upgrades, duplicate-ID normalization, repeat normalization, index wrapping, stable-ID resolution after reordered records, explicit versus disallowed fallback when an ID disappears, and consumption cleanup.

A self-menu action captured before reordering still opens its intended syringe; after that syringe disappears, the callback cannot silently open a replacement. Opening retains the supported native barrel size and the existing fallback for unsupported sizes. The current Body Map rendering shim delegates to the common carousel, whose selected-index reader is checked; its visual layout is not rewritten or certified by these tests.

Removal chooses the existing nearest-row fallback and clears pending site/dose/flush/injection/discard state. Other providers' stored rows are left intact. No new selection algorithm or serialization format is introduced.

### Tag metadata and preparation

Actual pending-tag and stored-tag functions retain the existing color plus three text fields. Tests cover the existing 25-character clipping on finite ASCII inputs, mixed-case and literal text, empty/typed/missing metadata, and preservation of medication, dose, component list, stable ID and barrel metadata. The active stored editor does not request a full redraw on each keystroke; only overlength text is rewritten. A missing display or missing selected record cannot redirect editing into another syringe.

Color selection acts on the stable selected record, preserves its other fields and resets the selector. Pending-editor extraction reads the three existing controls and leaves staged text unchanged after the display disappears. The memory reader retains the existing newest-three/marked-syringe presentation rule without changing medication records.

Compound and flush Save are executed using the existing source-funded preparation fixture with the actual pending-tag function replacing its old tag stand-in. The saved rows carry the tag while retaining their mixture and source debits. The separate native/cardio save paths are checked for actual call tokens to the same tag helper. Waste Draw is staging-only now; the historical assertion is moved to the real flush Save path rather than reinstating a write during Draw.

This does not claim that every asynchronous native draw/injection callback, real caret/IME behavior or every rendered label has been validated. Unicode grapheme counting and normalization are not modeled by the finite ASCII length cases.

### Personal-kit lifecycle callbacks

The actual registered Killed/Respawn callbacks clear their supplied unit's personal prepared-syringe store and the existing selected-ID/index mirrors; Respawn also clears the existing site selection. The callbacks do not remove a patient's tube/HPMK evidence or another provider's kit. The source registration remains reachable from startup and the non-interface guard prevents installation on a headless machine.

This verifies the callbacks and their registration boundary, not the engine's real event inheritance/dispatch on every respawn or control-transfer mode. It does not certify cancellation of all outstanding preparation callbacks after a lifecycle transition. Those asynchronous paths are outside this batch; no global death cleanup or inventory policy was added.

### Native dogtag cache

The current `ace_dogtags_fnc_getDogtagData` override is implemented in the native core source, not the retired `ACME_native` delegate. The source registration and native consumer are checked directly.

Execution verifies that valid three-string core identity caches, including the optional fourth field, are returned unchanged without regenerating a name or SSN. Absent, wrong-type, short and invalid-core-field caches are regenerated once using the existing native sources, then reused on the next read. Missing blood type follows the native generator; optional weight follows its existing setting. Dead-patient identity remains available. Name, SSN, blood-type and weight source primitives are deterministic fixtures; their real generation distributions or clinical data are not certified.

## Local verification

The focused preservation/lifecycle/clinical suite passes **1,100 tests plus 400 subtests**, without failures, errors or skips. It includes the prior 1,019-case set, 72 new execution cases and nine refreshed historical outcomes. Full-project `hemtt check` returns **0**; its seven existing non-blocking style suggestions are deliberately unchanged.

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 232 | 223 |
| Passing tests | 3,055 | 3,136 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Identity-based comparison finds **nine previously failing outcomes now passing**, **no newly failing identities**, **no comparable passing outcomes regressing**, and **no missing prior outcome identities**. Both broad-suite commands return exit code 1. The remaining 223 failures are not waived, skipped or marked harmless.

The new cases also run against the unchanged starting runtime as a reference check. This batch does not need a red-green production fix: the tests demonstrate current behavior, and the complete-tree check forbids any runtime or asset change. Existing tests outside the nine reviewed bodies remain unchanged. No global monkeypatch, outcome rewriting, new skip filter or xfail suppression is introduced.

## Limits and release scope

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Engine display/control/event/item boundaries are stand-ins; selected-ID, metadata, cache and callback source logic executes as checked in. The UI adapter records text and selector operations rather than rendering controls. Existing source-funded preparation fixtures retain their documented finite-input/map/transport boundaries. Self-menu iteration adapts unsupported VM continue without replacing its conditions or row identities.

No Arma client or dedicated server ran. No claim is made about live networking, rendered geometry, every delayed-event interleaving, or broad gameplay freedom from bugs. The remaining 178 original source-contract identities and all other unresolved failures remain visible in the index and evidence ledger.

**No gameplay rebuild is required for this test/documentation-only batch.** Keep the previous stash as a backup and do not reapply superseded patch installers. This work does not change the running mod's behavior.

## Independent clean-checkout verification

GitHub Actions run **35805536891**, job **107005394504**, independently verified candidate **584195002038e4c8b1b03840da084ef5e06286d8**, parent **f5f2c3b436a3462103256f78596df1fcf9653d7d**, and complete tree **f5aad244197d2d442d3dc9c30e6db1830bed986c**. The reviewed patch matched SHA256 **99b0f445ff4f63b89db93a2e9d8d1f52f977c68a0cbdf010811d88b9bfe83893**. The candidate source was not changed to satisfy the independent run.

The focused suite independently passed **1,100 tests plus 400 subtests**, with no failures, errors or skips. Full-project HEMTT returned **0**. The complete broad runs matched the table above: **nine previous failures now passing, no newly failing identities, no comparable passing-outcome regressions, no missing prior identities, zero collection/setup errors and four unchanged skips**. Both broad-suite commands still returned **1**; successful validation is not a clean broad-suite result.

The independent reference control copied only the two new test modules onto the unchanged starting checkout: **all 72 cases passed**. This verifies the examined current behavior without a production change. Exact-tree and existing-test AST checks restrict the candidate to **eight added/modified test/documentation paths** and **nine intended existing test-body changes**. All **4,025 other existing paths remain unchanged**, with **no deleted files and no runtime or asset changes**. The audit workflow, settings bundle and transferred patch payload are not in the production candidate. The follow-up changes only this report to record the independent results.

Raw commands, return codes, before/after outcome streams, JUnit results, reviewed patch, test-edit scope, preservation proof and candidate identity are retained in artifact **10727413902**, `historical-backlog-batch8-results`, SHA256 **2f6222e5648a0d093934a76fc50f46040557ed7f35476d73980ebdbc2c2d8de5**. The evidence package retains the complete **460-outcome ledger** and **178-entry unresolved original source-contract index**.
