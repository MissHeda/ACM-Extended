# Historical backlog, batch 9: IO syncope lifecycle and native boundaries

## Publication status and source

**Prepared and tested locally; not pushed to GitHub.** The available GitHub connector actions in this turn support reads, not commit/push operations. The existing installed integration was checked; no new remote branch, workflow, commit or ref update was made. This is not an independently executed GitHub Actions batch.

Published base: `1aaf9953e0036babbe37c9800cd32e1768c66600` (Batch 8).
Complete published tree: `584852ec6cb571122b5bdb96842bfda9306921ff`.
The complete local checkout was reconstructed from the pinned source/assets and the published batch patches. Its Git tree matched the published tree exactly before editing. The unchanged baseline and candidate ran in separate local worktrees with the same installed toolchain.

Only two runtime paths change:

- `addons/acm_extended/functions/fn_ioPainResponse.sqf`
- `addons/acm_extended/functions/fn_ownerInit.sqf`

The remaining changes are two new test modules, five selected historical test bodies in three existing modules, this report, and the remaining-work index. No dose, concentration, kinetics, sedation/seizure threshold, blood-flow calculation, animation, layout, inventory rule or new background worker was added or retuned.

## Necessary IO corrections

### Pre-reset callbacks could consume a new episode's reused serial

IO fluid schedules the existing delayed syncope with a per-patient serial. Full heal clears both `ACME_ioSyncopeSerial` and `ACME_ioSyncopeToken`; clinical reset separately increments `ACME_clinicalEpoch`. The old callback checked only the serial. Consequently a new post-reset flow can reuse serial 1, allowing the still-pending pre-reset callback to trigger too early and retire the newer job's reservation.

The callback now captures and checks the existing clinical epoch before changing its token or requesting unconsciousness. It also checks its issuing owner and rejects a restore in progress. The entry point rejects a restore in progress before changing pain or scheduling new work. A superseded callback cannot clear the replacement job's token.

The reset reproduction uses the actual names and generation behavior confirmed in clinicalReset/clearAllAilments, but it does not execute the whole full-heal function. This VM retains nil-valued namespace keys differently from Arma objects, so the test supplies their real post-deletion read defaults (-1 for the token, 0 for the serial). The production epoch reader and IO helper execute unchanged apart from the reviewed fix.

### Ownership transfer could strand the pending timer

The old Local-event handler did not invalidate IO syncope reservations. If the originating machine loses ownership while its timer is pending, the timer exits on the locality guard. The original machine can retain that token after ownership returns, preventing subsequent flow from scheduling another timer. A quick away-and-back handoff could also leave the old callback able to act.

The existing Local-event handler now clears the machine-local pending IO token. The existing serial is retained, so a subsequent job receives a new serial. No new owner-transfer loop, network publication, patient-state reset or equipment teardown is introduced. The tests execute the actual Local-event body with unrelated scheduler/engine boundaries stubbed and cover both firing the old callback while away and returning before it fires.

### IO syncope still used the low-level unconscious-state setter

The delayed IO callback was another direct caller of `ace_medical_status_fnc_setUnconsciousState`, despite the public medical-entry route used by the earlier repaired unconsciousness sources. It now calls `ace_medical_fnc_setUnconscious` with `[patient, true, 0, false]` after the existing already-unconscious check.

ACE's published medical API and implementation identify this as the public entry point; it activates medical handling when needed and sends the normal knockout event. The change does not add a wake timer, alter wake eligibility or bypass another unconsciousness cause. The execution tests record the public/low-level boundaries; they do not run the real CBA medical state machine or certify an in-game recovery.

The existing IO policy is preserved: placement retains its configured minimum pain; actual admitted IO fluid and flushes retain the configured delayed syncope; medication boluses retain their separate severe-pain-only mode. Repeated flow does not add another pending timer or restore the old explicit repeated injury-sound loop. Dead-patient interaction availability elsewhere is unchanged; this physiology helper already excluded dead patients.

## Historical outcomes resolved in the local candidate

Five original identities now pass: **H166, H167, H395, H396 and H410**.

H167, H395, H396 and H410 are four of the previously remaining 178 source-contract outcomes. The candidate index is therefore **174**, while the published index remains **178** until this patch is applied and published. H166 is the separate first-assertion IO case that was not part of that subset.

Across the original 448 failed outcomes, the candidate has **251 passing and 197 still failing**. The published baseline remains at **246 passing and 202 failing**. The original seven collection and five setup errors stay separately tracked as resolved; all 460 original ledger identities are retained.

The refreshed contracts verify:

- The ACE-facing volume bridge forwards its complete arguments and canonical return exactly once, instead of demanding another copied integration body.
- The positive-admitted-volume and IO-type gate in the canonical circulation transaction reaches the actual IO helper. The owner medication-line transaction preserves medication-versus-flush mode and rejects duplicate receipts. Whole bag integration and downstream physiology are outside the fragment tests.
- The canonical volume exit retains all four finite-value checks and routes invalid values to the existing fallbacks while preserving valid compartment values. The engine finite predicate is a controlled boundary; no fake NaN value or claim about the engine's IEEE behavior is made.
- The delayed native-binding diagnostic stores its full result and detects missing or mistyped function bindings, rather than requiring a retired status mirror. Binding implementations are test fixtures; this does not certify every live startup override.
- The treatment override remains registered under the native core CfgFunctions owner, rather than restoring a redundant Extended registration. This is a configuration/source check, not execution of all treatment branches.

Only the five named existing test bodies change. No unrelated test is removed or renamed. The old test demand for direct pain writes and a low-level unconscious setter is replaced with checks of the current state-writer and public-entry behavior, not a rollback to obsolete code.

## Local verification

| Broad historical addon suite | Published baseline | Local candidate |
| --- | ---: | ---: |
| Failing outcomes | 223 | 218 |
| Passing tests | 3,136 | 3,215 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Individual-outcome comparison finds **five previous failures now passing, no newly failing identities, no comparable passing outcomes regressing, and no missing prior outcome identities**. Both broad commands still return exit code 1. The 218 remaining failures are not waived or marked harmless. Only equivalent checkout-root text in rendered path contexts is normalized for identity comparison; assertions and outcomes are not modified.

The focused suite passes **1,179 tests plus 400 subtests**, with no failures, errors or skips. It retains the previous 1,100-case focused set and adds 74 new regression cases plus the five selected historical identities. Seventy-three of the new cases invoke SQF-VM; one checks native configuration registration. Full-project `hemtt check` returns **0**, with seven existing non-blocking style suggestions left unchanged.

The controlled unchanged-source run copies only the two new test modules onto the baseline: **11 failed and 63 passed**. The same **74 cases pass** on the candidate. These are failed regression cases, not eleven distinct gameplay defects. They include explicit negative lifecycle/restore/owner fixtures and verification of public API routing. Initial fixture-development runs are not the final red/green evidence.

Exact patch application is also checked on another clean worktree of the same base. The complete resulting tree must match the reviewed candidate, and the new cases are rerun there. No remote CI execution or GitHub publication is claimed.

## Execution limits and release scope

Toolchain: Python 3.13.5, pytest 9.0.2, HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Scheduling callbacks are captured and invoked in chosen orders; the real engine scheduler does not run. Engine object/locality, pain/status APIs, selected catheter identity, inventory/delivery boundaries and the finite predicate use explicit stand-ins. The owner Local-event body, IO helper, clinical epoch reader, medication-line transaction and selected canonical exit/gate fragments execute from the checked-out source.

No Arma client or dedicated server ran. The tests do not prove live locality-event ordering, actual full-heal/restore interleavings, CBA state-machine behavior, waveform/rendering, injury sounds or downstream pharmacokinetics. There is no guarantee of zero future bugs. The unresolved historical tests remain visible.

A rebuild is needed after applying this patch because it changes two runtime files. Live checks should exercise admitted IO fluid, medication boluses versus flushes, repeated flow, reset between two scheduled reactions, and patient locality loss/return. The configured pain and delay must remain unchanged, old jobs must not consume new ones, and ordinary wake/recovery behavior must still follow the existing medical system.

Do not pop the old stash or rerun superseded installers. The supplied standard Git patch targets the exact published Batch 8 base; it is not another source-block search-and-replace installer.
