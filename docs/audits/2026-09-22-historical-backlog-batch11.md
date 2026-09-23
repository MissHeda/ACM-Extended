# Historical backlog, batch 11: native medication effects and catheter retirement

## Source and scope

Starting commit: `215d5187e6c8caaf57681edc0707e93e5f6abd98`, complete tree `f0bf6e4f383b3494bc997cf160a85531a8e30f0e`. The current GitHub reference was read before editing. A fresh, pinned GitHub checkout supplied the tracked-text snapshot, raw commit and complete manifest. Retained binary assets were hash-checked against that manifest; the reconstructed local repository matched all 4,038 tracked paths and the exact starting tree. A separate unchanged worktree supplies the baseline.

This batch changes only **two runtime lines in two files**. The remaining changes are two new execution-test modules, nine selected test bodies in one existing historical module, and this report. No medication concentration, dose, effect curve, onset/washout timing, sedation threshold, seizure weight, blood-flow algorithm, inventory policy, animation, UI layout, registration, event type or worker is added or retuned. The prior ten backlog batches are retained.

## Confirmed corrections

### Atropine cleared a different spasm variable than the airway reads

`fn_medicationCBRNTick.sqf` includes the circulation component header. Its `QGVAR(AirwaySpasm)` write therefore addressed `ACM_circulation_AirwaySpasm`, while `HAS_AIRWAY_SPASM` reads `ACM_CBRN_AirwaySpasm`. The existing atropine eligibility branch could succeed without clearing the native airway-spasm state.

The single write now uses `QEGVAR(CBRN,AirwaySpasm)`, matching the shared reader. The effective-dose threshold, buildup reduction, arrest factor, time normalization and conditional probability are untouched. Four unchanged-source cases reproduce the mismatch, one for each existing atropine alias. Below-threshold, zero-onset, ineligible-owner, dead-patient and zero-delta cases preserve the existing exclusions. The low-buildup branch is deterministic in these tests; random spasm-clear probability is not calibrated or certified.

These are the mod's chemical-buildup equations, not clinical toxin-treatment or dosing advice.

### Catheter bag cleanup compared Boolean access kinds with numeric inequality

The bag-retirement loop in native `fnc_setIVLocal.sqf` used `_bagIV != _iv`, even though the selected and bag access kinds are Boolean. Executing that branch produced `Unknown input combination BOOL != BOOL` in SQF-VM. The error occurs after line-generation/queue handling and before bag cleanup completes; the test result does not establish a live multiplayer inventory-loss incident.

That comparison now uses `isNotEqualTo`. The following site comparison and the remainder of the custody/return algorithm are unchanged. Fourteen unchanged-source cases reproduce this branch failure. Coverage distinguishes IV from IO independently of site numbers, preserves other-line bags, exercises ordinary returns, retains medicated/special/non-convertible bags by UID, and repeats on live and dead patients.

No new access-removal rule is introduced. Pending in-line medication still belongs to its old physical catheter and is recorded as discarded when that line changes; unrelated queues survive. Identified bag contents are not converted into an ordinary bag or silently thrown away. Already-admitted infusion settlement is a recorded boundary call in these tests, not a reimplementation or validation of downstream kinetics.

## Nine historical outcomes closed

The nine failures are in `test_na8_5_batch13.py` and were exposed when batch 1 repaired collection. They are **not part of the original 448 failed outcomes or its 164 remaining source-contract subset**. Those original counts therefore remain unchanged: 263 of the original failures pass, 185 remain failing, and the seven original collection plus five setup errors remain separately recorded as resolved.

The selected historical identities retain their names. Only their nine test bodies are updated:

- `EffectAndLifecycleContracts::test_shared_cardiac_reader_uses_dose`
- `EffectAndLifecycleContracts::test_shared_nausea_reader_uses_dose`
- `EffectAndLifecycleContracts::test_b14_naloxone_is_vanilla_not_temporary_antagonist`
- `EffectAndLifecycleContracts::test_opioid_threshold_not_disabled_below_one_mg`
- `EffectAndLifecycleContracts::test_cbrn_no_timed_pfh_onset_termination`
- `EffectAndLifecycleContracts::test_removed_catheter_clears_its_pending_drugs`
- `EffectAndLifecycleContracts::test_external_count_delegate_is_separately_registered`
- `SuctionAndSALAD::test_no_penalty_double_application`
- `SuctionAndSALAD::test_suction_updates_before_native_oxygen`

Removed Extended override paths are replaced with their actual native source locations, not recreated files or a global redirect. The retired external count-delegate name is replaced by checks of the actual ACE-facing registration and behavior with foreign medication classes. The old inline naloxone-latch expectation follows the existing shared commit helper. No unrelated historical assertion or identity is deleted, skipped or marked expected-failure.

## What execution covers

Native cardiac/nausea readers execute with the actual medication envelope and availability functions. Cases cover admitted amount, existing caps and thresholds, onset, unrelated records before/after matching records, antiemetic suppression, foreign class names and body-site filters. Bound rocuronium changes effective count without changing raw admitted amount. Reader tests do not mutate stored medication rows or retune those algorithms.

The actual admitted-exposure tracker and toxicity-latch writer preserve other drug-family latches, mark only the current opioid generation after naloxone, and allow subsequent exposure to advance the generation. No temporary antagonist is inserted by that bookkeeping path. The actual native usage handler keeps positive reference thresholds below one and issues one callback for total/bolus excess rather than two. The overdose callback and its later physiological consequences remain a boundary fixture.

Catheter tests execute the full native setter and physical-line identity helper. They cover exact IV site/IO/legacy-queue retirement, replacement generations, repeat removal without duplicate discarded-dose accounting, invalid parts/sites/epochs, nonlocal forwarding and bag custody. Bag UID lookup, native inventory primitives, return-volume selection, inventory class existence and infusion-delivery calls are explicit fixtures. They do not prove actual remote inventory replication, item packaging or downstream infusion settlement.

Suction cases execute the full current debt tick and its initial handoff into the native oxygen target. They verify existing grace/ramp/support factors, handheld/parked modes, multiple valid session entries without multiplied debt, invalid-session retirement and one target deduction. The rest of native oxygen physiology and equipment arbitration are outside this fragment's scope. No oxygen algorithm changes.

## Local verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 206 | 197 |
| Passed tests | 3,324 | 3,468 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Identity comparison records **nine existing failures now passing**, **zero newly failing identities**, **zero comparable passing-outcome regressions**, and **no missing prior outcome identities**. Both broad commands return exit code 1. The four existing skips are unchanged. The remaining 197 failures are still open, not cleared or harmless by assumption.

The focused suite passed **1,432 tests plus 400 subtests**, without failures, errors or skips. It retains the prior 1,288-test selection, adds 135 new cases and the nine refreshed historical checks. The complete affected historical medication module, together with the new modules, also passed: 259 tests plus 26 subtests. Full-project `hemtt check` returned **0**, with the same seven non-blocking style suggestions left untouched.

The controlled old-source run copies only the two new test modules onto the unchanged baseline: **18 failed and 117 passed**. Those same **135 cases all pass** against the corrected runtime. Four failures expose the CBRN namespace mismatch and fourteen expose the bag-access Boolean comparison. Initial harness-only issues (trace macros and the unsupported continue primitive) were corrected in the test adapter, not runtime, before this final control.

Exact-tree and AST checks restrict the change set to six added/modified paths, preserve all unrelated test bodies, and leave **4,035 other existing paths unchanged**. No files are deleted. The unchanged original 460-identity ledger and the separate nine newly-exposed outcomes are included in the evidence; the original 164-entry remaining-work index is not artificially decremented.

## Execution boundaries and release status

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Engine object identity, publication, time-delta calculation, native inventory/config queries, selected callbacks and some unsupported finite-input/linearConversion/map-default primitives are explicit fixtures. The test adapter asserts the CBRN and medication macro definitions against the checked-out headers. For sources with one unsupported `continue`, it introduces an iteration-local named scope; skipped records advance to the next original loop record rather than terminate the whole function. This adapter is not used to edit production source.

Only finite numeric inputs are claimed for the finite primitive fixture. The tests do not certify real random distributions, all malformed save states, biological medication effectiveness, multiplayer delivery, or full Arma scheduling/engine integration. No Arma client or dedicated server ran.

A gameplay rebuild is required for these two runtime corrections. Targeted live checks are an existing CBRN airway-spasm scenario with sufficient active atropine, and IV/IO removal with ordinary, medicated and special bags while another line remains present. Repeat removal on a dead patient without losing equipment evidence or restarting physiology. Check the actual release package separately before any public/stable promotion. **This batch is not a stable-release sign-off.** Keep the old stash and do not reapply superseded patch installers.
