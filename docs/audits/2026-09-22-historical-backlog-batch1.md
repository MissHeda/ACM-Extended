# Historical backlog, batch 1: runnable tests and current clinical contracts

## Scope and result

Pinned starting commit: `19d01b8b27fd53bb9d3c381c7445add589336159`.
This is a **test-infrastructure and test-contract update**, not a gameplay patch.
No SQF, addon configuration, assets, medication values, animation timing or patient-state logic changed.
The previously repaired four runtime defects remain unchanged.

The original source-contract subset goes from **262 unresolved outcomes to 249**. The 13 resolved identities are H059, H060, H061, H062, H064, H065 (CPR/BVM/junctional), H089, H090, H092 (thoracostomy access/inventory), and H441, H443, H445, H448 (IV difficulty/selection/gauge). This does not clear the remaining 249 or make the broad suite green.

## Reproduced broad addon-suite results

HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5 were available for both runs; Python/pytest versions are recorded in the evidence. Only the historical addon tools directory is counted here. The repository-root historical tools are a different scope.

| Source | Failed outcomes | Passed | Skipped | Collection/setup errors | Passing subtests |
| --- | ---: | ---: | ---: | ---: | ---: |
| Unmodified 19d01b8b | 460 | 1,796 | 4 | 12 | 2,747 |
| Batch 1 candidate | 299 | 2,505 | 4 | 0 | 5,518 |

Before: seven collection errors and five shared SVT setup errors. After: zero collection or setup errors. The unchanged four skips include unavailable packaged-release fixtures and an existing experimental-feature check, not newly suppressed failures.

The baseline consistently excludes B77 because its module-level sys.exit prevents collection. The candidate refactors B77 to collect every retained check, without excluding it. Collection repairs also expose additional tests and subtests in other modules. Therefore the total test populations differ; a simple raw subtraction is not an adequate accounting of fixed defects.

Identity-based comparison found **183 previously failing outcomes now passing** (160 parent-test reports and 23 subtest reports), **22 newly exposed failing identities**, and **zero previously passing comparable outcomes regressing**. The 22 new failures are five animation assertions in B31 treatment animations, one B37 menu-state assertion, two B38 mixture assertions, four B80 head-menu assertions and ten batch13 medication assertions. These remain visible and unclassified, rather than being bypassed. These are newly executable failures, not proof of 22 new runtime regressions.

Of the original quoted 448 failed outcomes, **173 now pass and 275 still fail**. The 173 include one Hang Bag outcome already fixed before this batch. Thus this batch makes **172** additional original failures pass, plus eleven activated execution failures outside that original count. The 12 original error identities are tracked separately: their modules now collect or their obsolete setup has been replaced by current contracts.

Original outcomes now passing comprise:
- 100 source-location repairs with original assertions retained;
- 47 previously version-blocked tests now passing their complete remaining assertions;
- 12 client-setting outcomes (including subtest identities);
- 13 clinical/source-contract outcomes from the previously unresolved 262;
- one pre-existing Hang Bag fix in the pinned baseline.

The 48th version-first test, H306, now gets beyond its old version assertion but still fails on a removed ROSC helper/registration assumption. It remains open; no old ROSC gate was reintroduced to satisfy it.

## Changes and supporting checks

### Read-only source locators

A new opt-in `historical_source.py` maps 42 explicitly known retired Extended override paths to their native implementations. Unknown/missing paths still fail. No Path method, pytest report, assertion, import hook or production file is monkeypatched.

Startup/debug aggregation follows actual init/register/debugMenu call tokens into the called modules. Comments and quoted sample calls are ignored; missing called files fail; repeated calls/cycles are bounded. This is source-presence evidence, not proof that every branch executes in the game.

The mechanical locator pass updates explicit source-read call sites in 78 historical modules without changing their assertion AST counts. Hand-reviewed changes are separated in the evidence diff.

### Release and CBA setting contracts

111 obsolete release-literal assertions across 47 modules now check valid, consistent shipped config/runtime version and build identity, rather than requiring old r7/r28/r42 or 1.2.0-r0 stamps. Later non-version assertions remain active. The release helper has negative tests for mismatched fallback, invalid format and invalid build stamp.

The client-setting assertions inspect the actual sixth CBA setting argument, not an arbitrary zero in a nested array. CBA's own settings init source documents scope 2 as not overwritable and scope 1 as shared. The current accessibility/debug declarations use 2. Tests reject both 0 and 1 for the stronger current client-only contract, reject missing/duplicate declarations, and do not change the settings themselves.

### Collection and fixtures

The compound-plunger parser includes the actual mouse clamp step and defers its regression checks until the plunger test runs. Importing its expression parser no longer prevents unrelated animation tests from collecting.

Medication matrix consumers use the repository's existing source inventory generator in memory from the checked-out native medication definitions plus Extended overrides. No external sibling checkout, fabricated medication definitions or committed generated matrix is required. This source inventory is not an Arma preprocessor or a clinical dosing reference.

B77, B80 and B91 no longer throw assertions/exit during module import. Their retained contracts become individual tests. The B91 flashlight filter check inspects its actual module rather than unrelated startup modules.

The SVT setup was requiring a retired exception preserving atrial rhythms above the native fatal high-rate boundary. Its replacement exercises the actual native-rate/overlay gates, including exact threshold boundaries, native rhythm/arrest takeover, torsades ownership, watchdog event scope and pain-feedback separation. It does not change the game's thresholds or restore that exception. Nineteen cases pass.

### Actual clinical execution coverage

CPR/BVM tests now follow native PREP/action registrations, actual role-reservation predicates and owner-side junctional transitions. They execute ventilation while another provider's CPR marker is present, retain the other role, verify unavailable/out-of-range providers fail their reservation predicate, and exercise current packing/wrapping state writes. Source checks retain the public marker contract; simulated transport is not real networking.

Thoracostomy tests verify loss of permission/kit blocks cutting or clamp release before a patient-state commit. Valid release still commits. Disposable kits require a verified inventory receipt; reusable kits are not consumed. Tube projection follows both permission and a successful debit. The current side-state writer is checked instead of demanding removed inline setVariable text.

IV checks exercise the current pressure/BOA/gauge/EJ calculation and binding to the selected site. The actual algorithm runs in SQF-VM with blood-pressure/catalog boundaries mocked. SQF-VM's unsupported finite/linearConversion primitives are explicitly represented by bounded finite-input and affine-map mocks; NaN/Inf validation and actual vein-catalog anatomy are not claimed as tested by those cases. No pressure thresholds or gauge multipliers were retuned.

### Existing execution-fixture repairs

The BVM/Direct Pressure fixture now executes the checked-out directPressureMarker owner branch rather than silently discarding that command. The push-seconds input fixture supplies the expected control stand-in. The chest-viewer fixture supplies its actual front-side/vest-handoff state. Namespace stand-ins remove only a real top-level public flag, preserving nested values and handling explicitly compiled input-code strings. Tests cover strings/comments, nested Booleans, multiline writes and nonliteral public arguments.

The burp test follows the current trauma-versus-thoracostomy presentation split. Its pressure/effect, repeatability, logging and dead-patient physiology assertions remain active; only the obsolete extra-gesture count differs.

## Validation and remaining limits

Local focused suite: **452 passed, 400 subtests passed**, no failures/errors/skips. This includes the previous 184-case preservation/lifecycle/consciousness/seizure/configuration suite, new helper tests, clinical cases and repaired execution fixtures. Full-project `hemtt check`: **exit 0**, with seven existing non-blocking style suggestions unchanged. The source-preservation hashes remain enforced.

Independent GitHub Actions run **35771015212**, job **106892433471**, reproduced these results from complete checkouts. It verified the exact reviewed tree **28a46689ec00280c88576728338e6acc37b4a84d**, ran the 452-test focused suite with 400 passing subtests, passed full-project HEMTT checking, and reproduced both broad-suite rows above. Its outcome comparison recorded 183 previous failures passing, 22 newly exposed failures, no comparable passing-outcome regressions, zero collection/setup errors, and the same four skips before and after. The broad suite still returned exit code 1; the successful validation workflow does not mean that suite is clean.

The independently validated candidate is **4d2b6c737088bb4bad72eeb423924229e586b56e**, with parent **19d01b8b27fd53bb9d3c381c7445add589336159**. Its 89 added/modified paths are restricted to Python test helpers/tests and the two audit documents. The final follow-up only records this independent verification in this report. The audit preparation workflows and intermediate patches are not part of the candidate's tree.

The candidate's production/asset bytes are verified against the complete pinned manifest. No files were deleted. No failures were mass-marked xfail, no new skip filters were added and no retired gameplay behavior was restored for a test.

The remaining original 249 source-contract IDs are indexed in `historical-backlog-remaining-20260922.txt`. The full 460-outcome disposition ledger, before/after logs, newly exposed failures and test-only diff accompany the evidence archive. The 299 broad failing outcomes remain work, not a waiver. Resolving a source assertion is not the same as proving gameplay bug-free.

No Arma client or dedicated server ran. Live rendering, animation integration, equipment inventory and real multiplayer transport ordering remain outside these mocked execution tests. This batch does not require a gameplay rebuild merely to obtain its test/doc changes.
