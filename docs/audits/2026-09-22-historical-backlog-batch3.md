# Historical backlog, batch 3: shared vials and source-funded preparation

## Scope

Starting source: `539c7e802261b78247a74f1208b3170a75a4734a`, complete tree `cdbae0c7945de62417eb98267f018442b6642d3c`.
The local complete source/assets were reconstructed from the pinned archives and published batch-1/batch-2 changes, then checked against this exact Git tree before editing.

This batch corrects **two confirmed control-flow defects** in the shared-vial path. Three vial helpers change; four existing callers now pass their captured provider explicitly so the corrected guard does not break an original provider's own-inventory refund after a control switch. Thus **seven runtime paths** change, with no configuration, asset, medication concentration/dose, onset/washout threshold, seizure weighting, blood-flow, animation or UI layout change. Existing lease/retry/renewal durations and the existing micro-residual handling policy remain unchanged. This is not an inventory-transport redesign.

## Confirmed defects

### Pending claim replaced before its acknowledgement

In `fn_vialLeaseEnsure.sqf`, the pending-request `exitWith` was nested inside a secondary block. It left that block, not the surrounding acquisition path. A stock refresh while waiting could therefore generate a replacement token and another claim on each call. A delayed valid acknowledgement could then be stale relative to the newly replaced token.

The pending predicate is now evaluated in the acquisition branch before the nested cleanup block. A matching unexpired pending request returns without replacing its token or sending another claim. Existing timeout replacement, old-token release, renewal and owner arbitration remain intact. No new polling worker or timer is added.

### Rejected lease did not stop inventory/ledger mutation

`fn_vialTake.sqf` and `fn_vialRefund.sqf` had the same nested-exit mistake. A missing, empty-token, expired or wrong-holder lease could fail the inner guard and still fall through to a stock debit or refund write.

Each helper now calculates the same lease validity and rejects at function scope before any inventory/ledger write. An optional fourth provider argument preserves the captured actor, rather than interpreting that actor's self-inventory as somebody else's after `ACE_player` changes. Legacy three-argument UI calls continue to use the currently controlled provider. The four callers updated for explicit actor identity are native Syringe_PrepareFinish, medicationTakeSources, infusionRefundSupplies and epinephrineTakeSource.

Properly acknowledged shared-person and vehicle sources still work, including a dead patient as an inventory holder. No new alive-holder restriction was added. Existing exact-volume arithmetic, source identity, dose calculation and residual policy were not retuned.

## Reproduction and validation

A controlled before/after run copied only the new vial test module onto the unchanged starting source. Four pending-refresh cases and eight invalid-lease mutation cases reproduced the defects: **12 failed and 2 passed**. The same **14 cases all pass** on the candidate. The two positive controls verify original-provider self-inventory behavior rather than presuming every test should fail on the old version.

The focused preservation/lifecycle/clinical suite passes **693 tests plus 400 subtests**, with no failures, errors or skips. It retains the previous 575-case focused set, adds 92 new executable cases, includes 16 existing shared-vial/clamp checks and the ten refreshed historical identities. Full-project `hemtt check` returns **0** with the same seven existing non-blocking style suggestions. Those suggestions were left unchanged.

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 283 | 273 |
| Passing tests | 2,628 | 2,730 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Identity-based comparison finds **ten existing failures now passing, zero newly failing identities, and zero comparable passing outcomes regressing**. Both broad runs still return exit code 1. The remaining 273 outcomes are not cleared, skipped or marked expected-failure.

Seven resolved identities belong to the original quoted 448 failures: **H016, H017, H046, H049, H050, H055 and H438**. Of those original outcomes, **196 now pass and 252 remain failing**. Six of this batch's resolutions belong to the original unresolved source-contract subset, taking it from **234 to 228**. H016 is the separate retired Save-dialog expectation. Three additional resolutions are the mixture/flush/source-funded dilution checks exposed during batch 1, not extra original IDs.

## What the tests establish

### Lease and stock boundaries

The new cases execute pending acquisition, acknowledgement matching, expiry replacement, stale replies, renewal cadence, release and competing-provider arbitration. Mutation tests cover valid and invalid leases, negative/zero/over-stock requests, partial-before-sealed consumption, multi-vial debits, refunds, manual next-vial unlock, repeated preview calls and absent sources. Existing self-inventory behavior is preserved across player-control changes.

These tests validate script scopes and request/ledger behavior with transport and inventory primitives mocked. They do not claim that real remote inventory replication or every network interleaving is simulated.

### Preparation, bag injection and plunger bounds

Actual source-funded preparation validates the complete component set before any debit, aggregates repeated components, preserves reusable containers, requires disposable inventory, and rolls back earlier solution takes if a later take fails. Rejected prepared supplies return to the original provider even if player control changes before the refund.

Bag injection rechecks capacity, session unlock and available stock before debit. A reduced valid amount synchronizes the numeric value, grab control and visual plunger offset, then requires reconfirmation. Cases also cover pending/missing bag state, missing syringe barrel, rounded source/dose agreement and refund on rejected bag registration. These use current native helpers; no retired competing cursor loop is restored.

The compound Save checks retain the approved immediate in-place transition and prevent a repeated Save from creating another stored syringe. The historical method name mentioning reopening is retained for ledger identity only; its expectation now verifies the current in-place behavior, not a removed close/reopen delay. Flush Draw stages a request; Save funds the actual components and carrier before storing the result.

### Owner-side medication handoff

The actual medication-line transaction preserves route, mixture and rate/site metadata, applies its systemic/leaked split, rejects duplicate receipts, drains queued medication only once and credits carrier volume only once. Stale catheter/provider/episode inputs do not drain the queue. Postmortem handling acknowledges without restarting physiology. Medication kinetics and clinical dose appropriateness are outside these tests.

## Historical-test maintenance

Native PREP registrations replace assertions demanding removed Extended override classes. Partial-vial persistence follows the existing open-vial writer. Stock/session limits follow the current native draw controller and authoritative bag checks. Named mixture labels are not used as a commit whitelist. Flush/source funding is checked at Save, not the staging-only Draw action. The original failing test identities and all remaining unrelated assertions stay visible.

No global test monkeypatch, new skip, xfail waiver, runtime rollback or mass rewriting of expectations was used. The new modules and selected existing assertions document their current boundary and execute the relevant source rather than treating a comment as proof.

## Execution limitations and release check

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Engine objects, inventory/config/UI and transport are explicit stand-ins. Unsupported getOrDefault and map iteration use equivalent operations on real VM maps; the particular adapted iteration bodies contain no break. An unused isNil return receives a terminal sentinel because the VM cannot evaluate the original void-ending callback. Only finite numeric inputs are covered by the finite/linearConversion stand-ins. NaN/Inf behavior, real item replication, rendered syringe geometry and downstream pharmacokinetics are not certified.

No Arma client or dedicated server ran. A gameplay rebuild is required for the seven runtime paths. In-game validation should use a second provider and a patient/vehicle vial source, confirm that waiting for ownership does not repeatedly replace the claim, verify stock cannot be drawn before acceptance or after rejection, and exercise partial draws, compound/flush Save, bag reconfirmation and rejected-preparation refunds. Preserve the old local stash; do not pop it or apply the superseded local patch scripts over this version.

## Independent clean-checkout verification

GitHub Actions run **35790135942**, job **106956380245**, independently verified source commit **202d715059a48e9caa31afde6a5735651fd96c94**, parent **539c7e802261b78247a74f1208b3170a75a4734a**, and complete tree **fda7f899236857bc228d8ddea6c9c6e2da450fce**. The reviewed patch SHA256 is **4131cf8bd3c98aeef8f8c7d66aa99724341445abbc45f663c33adb177bf28fb2**. All checks below ran against complete checkouts rather than an extracted source-only fixture.

The focused run passed **693 tests and 400 subtests**, with no failures/errors/skips. Full-project HEMTT returned **0**. The broad baseline and candidate results matched the table above: ten old failing identities passed, no newly failing identities or comparable passing-outcome regressions appeared, collection/setup errors stayed at zero, and the same four skips remained. Both broad-suite commands returned **1**; a successful validation workflow is not a claim that the broad suite is clean.

The independent unchanged-source control reproduced **12 failed and 2 passed**; those same **14 cases passed** with the candidate. The complete-tree check restricted changes to the seven named runtime paths, tests, and two audit documents: **18 added/modified paths, no deletions, no other production or asset changes**. The audit workflow and transferred patch payload are not in the production candidate. The follow-up changes only this report to record the independent results.

Raw commands, exit codes, JUnit results, before/after reports, reviewed patch, preservation manifest and verified candidate identity are retained in artifact **10721259219**, `historical-backlog-batch3-results`, SHA256 **0038ae9e55823dedb8631a7288914320be159187830484727df826f48326e10a**.
