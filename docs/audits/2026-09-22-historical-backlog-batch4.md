# Historical backlog, batch 4: chest assessment, menu policy and state cleanup

## Scope and provenance

Starting source: `d1b4cd550a7f93d7aa9536c731edcc4958387e45`, complete tree `ef8f13f1b445258abbe9d21039e9d405abaf2586`.
The complete local checkout was reconstructed from the pinned source/assets and published batch changes, then matched to that exact tree before editing. The original main reference was checked through the connected GitHub API.

Only two runtime files change: `addons/breathing/functions/fnc_inspectChestLocal.sqf` and `addons/acm_extended/functions/fn_obtundedTick.sqf`. The remaining edits are tests and audit documents. No configuration or asset changes, medication or seizure tuning, physiology thresholds, animation changes, UI/navigation redesign, additional network worker, or new equipment rule is introduced. All earlier lifecycle, pulse and vial fixes are preserved.

## Necessary runtime corrections

### Chest findings selected but omitted from their output

The breathing-patient pneumothorax branch appended an uneven-rise finding without adding its format placeholder. The hemothorax branch supplied three finding arguments to a two-slot hint and a primary log missing its last slot. With both injuries present, the first switch branch also prevented the bruising observation from being appended.

The corrected branch composes those existing observations together and supplies matching hint/log placeholders. Its hint height accommodates the additional line. Injury thresholds, the respiratory-arrest branch, localization keys, clinical/plain terminology, patient position and physiology are unchanged.

Two associated log indexing problems are corrected: mainstem intubation appended a placeholder one slot before its new observation, and the separate tracheal-deviation log reused the primary log's longer format despite having only three arguments. The former now points to the actual final argument; the latter uses its own three-argument format. No additional finding or diagnostic capability is invented.

Fifteen chest-assessment execution cases fail against the unchanged source and pass after this correction. Seven chest cases already pass and remain passing, including absent respiration, retained injury/equipment evidence on a dead patient and no assessment-induced repositioning or state mutation.

### Type-safe lucid-state transition comparison

The obtundation tick compared `_lucid` and `_prevLucid`, both Boolean values, with `!=`. The executable path fails in SQF-VM with `Unknown input combination BOOL != BOOL` before completing the active visual tick. This is not masked in the test adapter. The single-line correction uses the explicit any-type `isNotEqualTo` comparison, preserving the intended state-change truth table.

Seven execution cases reproduce that failure on unchanged source and pass after the correction. They verify initial entry, lucid onset, unchanged-window idempotence, expiry, manual preview while the master switch is off, inactive cleanup, and captured old effect handles not destroying a new episode's handles. No lucid-window duration, visual magnitude, audio level, voice policy or medical wake rule changes. This is executable source/type evidence, not a claim that a live Arma client was run.

## Historical backlog progress

Twelve original failed identities now pass: **H067, H068, H070, H083, H084, H085, H086, H088, H127, H128, H393 and H394**.
All twelve belong to the original unresolved source-contract subset, reducing it from **228 to 216**. Across the original 448 failed outcomes, **208 now pass and 240 remain failing**. The original twelve collection/setup errors remain resolved and separately tracked.

The tests preserve the current design instead of requiring retired behavior:

- Wrapped casualties have no patient-following blanket world object. Existing dropped HPMK anchors retain local visuals/pickup behavior. Prepped-kit return and mobile fallback are tested without adding an alive-patient interaction veto.
- Basic bedside assessments remain direct actions. Only the current equipment/injury/debug groups are treated as examination dropdowns. Chest/stethoscope and BVM routing follow exact current classes, not inherited labels or the old response/chest groups.
- Collected foreign actions retain callback, condition, item and icon values; collection does not execute treatment or eligibility. The current known-group ordering and native ordering of ungrouped actions are checked separately. A mismatched native/config prefix does not remap callbacks.
- Grouped/flat section logic preserves condition evaluation, open/closed behavior, body-site filtering, foreign actions and final standalone dog tags. Head-only assessment filtering is anatomy-based, not a death detector.
- Native reset clears bookkeeping without invoking Get Up, rolling the casualty, or removing unrelated equipment. The retired obtunded input/weapon shim removes its legacy display handlers without adding a projectile-deletion or weapon-interception path.

Historical method names are retained for outcome identity even where an old name mentions a retired visual/dropdown. Their revised expectations are explicitly documented, and they call execution checks of the current source rather than reintroducing obsolete runtime code.

## Verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 273 | 261 |
| Passed tests | 2,730 | 2,828 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Individual outcome comparison shows **12 existing failures now passing, no newly failing identities and no comparable previously passing outcomes regressing**. The broad suite still returns exit code 1; the remaining 261 failures are not cleared or waived.

The focused preservation/lifecycle/clinical suite passes **791 tests plus 400 subtests**, with no failures, errors or skips. It retains the prior 693 cases, adds 86 new executable/source cases, and includes the twelve retained historical identities. Full-project `hemtt check` passes with exit code 0. Its seven existing non-blocking style suggestions are unchanged.

An unchanged-source control adds only the two new assessment/state test modules to the starting checkout. It produces **22 failed and 26 passed**. The same **48 tests all pass** on the candidate, demonstrating that they detect the original failures rather than simply passing on any source version. The menu implementation itself is not changed.

The complete source-tree comparison restricts runtime changes to the two named paths, retains all unrelated source/assets and deletes no files. No new skip filter, xfail marking, pytest outcome manipulation or blanket rewriting of historical assertions is used. The source-preservation snapshot tests remain intact.

## Test boundaries and release check

Toolchain: HEMTT 1.22.0, SQF-VM v2026.04.03-ed9f5f5 and pytest 9.0.2. Object, config, localization, UI, sound, animation and transport boundaries are explicit stand-ins. The menu mapper/collector use fixture config arrays while their actual mapping, lineage and row-copy logic executes. Unsupported range-to-end select and map default reads are represented by their explicit equivalent operations. The HPMK test's single-patient loop replaces unsupported continue with a named-scope exit and does not claim multi-patient scheduling coverage.

Post-processing calls record their original arguments and captured handles; they do not create a rendered effect. The bounded affine-map helper stands in for unsupported linearConversion. The Boolean comparison is not replaced in the adapter. These tests do not certify live PP-stack interaction, network ordering, real inventory delivery, every player-switch scenario, actual config merging, localized rendered text or animation transitions.

No Arma client or dedicated server ran. A gameplay rebuild is required for these two runtime edits. Live validation should inspect isolated/combined chest injuries, mainstem and tracheal-deviation log entries, then confirm obtundation entry, lucid transitions and cleanup. Existing dead-patient evidence/equipment and direct-assessment menu behavior must remain intact. Keep the old local stash as a backup; do not pop it or apply superseded patch scripts over the current source.
