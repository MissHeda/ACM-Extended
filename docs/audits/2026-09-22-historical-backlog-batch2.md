# Historical backlog, batch 2: cardiac, pulse and airway contracts

## Scope

Starting source: `5e134975242f182ebbed1225c96709eb7b2cce96`, tree `a34ab4fc8b04985d0dcaf558359c6c1b1b6d0df2`.
The local checkout was reconstructed from the complete pinned source/assets and the published batch-1 diff, then verified to match this complete Git tree exactly.

This batch changes **two runtime files only**, both in manual pulse assessment. Everything else is tests or audit documentation. No dose/concentration, cardiac or sedation threshold, seizure weight, medication kinetics, blood-flow algorithm, animation, UI layout, network worker, or equipment inventory rule was retuned. The previous four lifecycle fixes and batch-1 work are preserved.

## Confirmed defects and minimal corrections

### Named pulse site passed to a numeric occlusion API

`fn_pulsePerfusionProfile.sqf` accepts body-part names but passed that name directly to `ACME_fnc_aajtOccludes`, whose switch accepts numeric ACE body-part indices. This returned false for AAJT occlusion, allowing a palpable pulse to be reported on the occluded limb. AAJT no longer creates a conventional ACE tourniquet, so the separate tourniquet check did not mask this mistake.

The correction converts the already-lowercased name to an index at the caller boundary. It does not change the shared occlusion API or other consumers. Six new cases failed before the correction and pass afterward. Coverage includes bilateral Zone 3 legs, unilateral inguinal and axillary placements, mixed-case caller names, unaffected sites, removal, and remaining conventional-tourniquet blockage. The electrical heart rate remains unchanged.

### Compression-generated pulse bypassed the occlusion check

The CPR branch of `fnc_checkPulseLocal.sqf` returned its simulated compression pulse before consulting the site's occlusion. Four additional cases reproduced pulse reports below an active Zone 3 device or conventional tourniquet. The correction consults the existing native tourniquet and AAJT authorities before generating that pulse. Patent sites retain the original compression-rate distribution and wording. Spontaneous pulse assessment continues to use the common profile.

These are two manifestations of a pulse-assessment defect, not new AAJT, CPR or perfusion physiology. The tests supply explicit engine/object stand-ins and a deterministic mode for the unsupported triangular random primitive; they do not establish real-world arterial palpability or validate a live Arma render.

## Backlog progress

Sixteen previously failing historical identities now pass:

- Cardiac/native precedence and monitoring: H008, H012, H306, H307, H308, H309, H312.
- Chest reset, treatment registration and surgical-seal boundaries: H095, H099, H116, H117.
- AAJT application and pulse occlusion: H293, H294.
- Suction, measured epinephrine and aftercare: H423, H426, H457.

Fifteen belong to the 249 remaining original source-contract outcomes. That subset is now **234**. H306 was the separate version-first/ROSC-registration outcome that batch 1 explicitly left open; it is now verified against native PREP registration and the current gate.

Of the original 448 failed outcomes, **189 now pass and 259 remain failing**. The original 12 collection/setup errors remain resolved from batch 1 and are tracked separately, not silently deleted. The remaining-work index continues to retain original IDs.

## What the refreshed contracts actually check

The ROSC path executes the native eligibility and attempt functions, including the strict blood-volume boundary, native oxygen/tension/hemothorax causes, Extended hypothermia/acidosis/toxicity vetoes, live/local/arrested eligibility, single successful transition, and shock-wrapper episode rejection. Extended ROSC-only vetoes do not disable circulation outside arrest. The post-arrest state flag and arrest clock remain handled by the existing transaction.

The ROSC event test verifies that acute paralytic and ventilator stress are cleared and the current grace period begins without erasing the historical awareness event. Native rhythm tests exercise the threshold observer's refusal to override an untreated critical rhythm, and the actual torsades-conversion fragment's maturity, bounded retry and acknowledgement checks. Monitor tests exercise proxy precedence and the cache-invalidation fragment and inspect the native consumer. They do not certify live waveform, sound or sweep timing.

Chest tests follow native PREP/event registration instead of retired Extended overrides. Executable checks verify that instructor clearing retires its old PTX episode/worker while preserving equipment, stale seal-peel effects are rejected, and a surgical seal cannot cover unrelated external wounds or clear the opposite tube. No cross-machine time comparison was reinstated.

Suction checks execute the actual compartment reader, drain transaction and native airway setter: partial debit, duplicate receipts, stale episode/session rejection, manual capacity, and vomit/blood/secretions separation. Measured epinephrine checks execute the actual stored-row debit before the mocked request boundary and verify dose/volume/remainder/refund conservation and selected-site rejection. These do not validate downstream pharmacokinetics or live inventory replication.

Aftercare remains usable on a dead patient without restarting physiology. The historical demand for an alive-patient rejection was replaced with tests of the existing live-provider/owner/episode/permission guards and dead-patient availability. No production aftercare change was needed.

## Verification

| Broad addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 299 | 283 |
| Passing tests | 2,505 | 2,628 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skips | 4 | 4 |

Individual-outcome comparison: **16 old failures now pass, zero newly failing identities, and zero comparable passing outcomes regress**. The four existing skips are unchanged. The broad suite still returns failure; 283 is not a clean result or a waiver.

The focused preservation/lifecycle/clinical suite passed **575 tests and 400 subtests**, with no failures, errors or skips. It includes 107 new executable cases and the 16 retained historical identities alongside the prior 452-case focused set. The new cases include negative input/owner/episode/session conditions; this is not simply a rewrite of expected strings. Full-project `hemtt check` passed with exit code 0; its seven existing non-blocking style suggestions were left unchanged.

Independent GitHub Actions run **35785840750**, job **106942311428**, reproduced the complete before/after results above. It verified candidate commit **c4258179096bec3bfafee65f13ed943ab0a0cff1**, parent **5e134975242f182ebbed1225c96709eb7b2cce96**, and complete tree **3fd0ddb07dc760897d159129322aba9cacf4fad7**. The focused run passed 575 tests plus 400 subtests; full-project HEMTT returned 0. The 14 added/modified paths contain only the two explicitly listed pulse runtime files, tests, and audit documents. No other production file or asset changed and no files were deleted. The follow-up commit only adds this validation record to the report.

The independent red-green control copied only the new pulse test module onto the unchanged starting source: **10 failed and 4 passed**. Those same **14 cases all passed** against the corrected candidate. This confirms that the pulse tests detect the actual pre-fix defects rather than simply passing on any version. Raw logs, JUnit results and command exit codes are retained in artifact **10720770487**, `historical-backlog-batch2-results`. The broad suite still returned exit code 1 in both before/after runs; successful audit validation is not a claim that the full historical suite passes.

Two earlier isolated validation attempts stopped at the exact patch checksum before applying source changes. Comparing transferred bytes identified three transcription differences in old/context lines. Those bytes were restored under strict before/after checksums; the original expected patch checksum and complete candidate tree were not changed. No unvalidated source was published. The audit preparation workflow and intermediate patches are not included in the production candidate.

Execution uses HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. The harness explicitly adapts engine object/publication boundaries and finite-input/linearConversion primitives. The single-patient threshold test maps unsupported `continue` to an equivalent named-scope exit; it does not claim to exercise multi-patient loop scheduling. Callback transport, inventory request delivery, localization and monitor UI are mocked. No Arma client or dedicated server was run.

## Release scope and next work

Only the two pulse runtime files need a gameplay rebuild. A live check should compare selected/unaffected limbs before and after AAJT placement/removal, repeat with conventional tourniquets, and repeat during CPR. Electrical monitor rate must not be changed by the pulse-assessment fix.

The remaining 234 original source contracts, the separate unresolved historical outcomes and the 22 failures exposed in batch 1 remain visible. Unrelated animation, medication and UI assertions were not skipped, marked expected-failure or rewritten in this batch. Do not apply the superseded local patch scripts or pop the old stash over this source.
