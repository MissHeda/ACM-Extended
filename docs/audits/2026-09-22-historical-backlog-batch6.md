# Historical backlog, batch 6: procedure selection and laryngoscopy reflex boundaries

## Scope and provenance

Starting commit: `f44efd601cad1f0f47c5f0bb28a37a9d42731ace`, complete source tree `38fdc4de9109a6dc8fd507266bde709d12c6f628`. The connected GitHub reference and commit tree were read before editing. The reconstructed complete local checkout matched that tree, including assets. The historical baseline ran in a separate unchanged worktree.

Only **four runtime files** change: `fn_thoraSelectTool.sqf`, `fn_thoraSlotHover.sqf`, `fn_laryngoPassTube.sqf`, and `fn_laryngoConsequenceLocal.sqf`. No configuration, dose, concentration, medication kinetics, sedation threshold, seizure weight, blood-flow rule, animation timing, layout, inventory-consumption policy or background worker was changed. The previous five backlog batches remain preserved.

## Confirmed defects and necessary corrections

### Rejected closure selection still altered the active procedure

The tube and seal guards in `thoraSelectTool` used nested `exitWith` statements. Rejection exited the inner block but did not leave the function. The code could therefore select the unavailable/disallowed tool, clear cutting/prepping state, and repaint as though selection succeeded.

The same permission, provider and stock predicates now reject at function scope, before any held-tool or current-step changes. No new eligibility rule was introduced. Tests reproduce six rejected cases on the old source: tube/seal selection after permission loss, stock loss, or loss of the captured provider. These are selection-state defects; they do not establish that final placement or item-consumption checks could be bypassed.

Valid selection still uses the captured provider, not a newly selected `ACE_player`. Selected tools can still be put down after their final item has been consumed or permission changes. The existing one-argument internal closure-putdown call remains compatible. Existing finger tracts retain their no-second-kit recheck path, while a new tract still requires equipment. Dead-patient interactions are not blocked.

### The old shared-slot hover rule survived the separate closure rows

`thoraSlotHover` still treated a held seal as if the tube slot were selected. With the current separate tube and seal rows, hovering the tube could incorrectly paint its black held-tool shadow while the actual held tool was a seal.

The selected predicate now compares only the real tool identity. Two old-source cases reproduce the incorrect tube shadow on hover entry/exit. Inventory refresh still preserves the selected tool and its shadow. Geometry, colors, hover timing and layout are otherwise unchanged; no control creation or per-frame worker is added.

### Explicit tube events bypassed the shared reflex exclusions

The owner-side `awakeTube`/`tubeManip` branch checked arrest but bypassed the existing shared helper's other zero-reflex exclusions. It could create emesis, consume the modeled remaining stomach count, play a gag sound, dislodge an OPA or start irritation for a now-paralyzed or dead casualty. An absent native reflex without an active drug-owned reflex state was also bypassed. Six unchanged-source cases reproduce those owner-side effects.

The owner now reads the existing `laryngoReflexChance` helper and rejects an explicit event only when it returns zero. It does not make a second random draw, alter the graded suppression calculation, or add a new sedation threshold. A positive, already-sampled explicit reflex still produces its existing finite event. The original receipt, clinical-epoch, distance and owner-routing checks remain intact.

The passage UI had a related disagreement: its low-sedation branch could declare a gag even when the shared reader had returned zero. It now requires a positive reader result before evaluating the existing low-sedation/random rule. Two unchanged-source passage cases reproduce that disagreement for dead/absent-reflex casualties. Tube interaction and appropriate item debit/placement remain available; death is not used to hide the action. The existing reactive unsedated case, drug-owned graded response and preinflated-cuff handoff remain covered.

## Backlog progress

Seven original failing identities now pass: **H093, H160, H420, H421, H422, H433 and H434**. All seven belong to the original unresolved source-contract subset, reducing it from **201 to 194**. Across the original 448 failed outcomes, **230 now pass and 218 remain failing**. The seven old collection errors and five old setup errors remain tracked separately as resolved, not deleted from the 460-outcome ledger.

The refreshed historical tests follow current delegation and explicit behavior:

- Tray shadow and provider/inventory checks execute the real selector, refresh and hover paths rather than require inline rendering/count text in the old locations.
- Successful passage exercises the actual sender and owner consequence handler, including miss reset, preexisting tube handling and repeat-call idempotence.
- The actual delayed abort is tested against a replaced display, different patient and closed view. Passage is synchronous now and is checked not to introduce a timer merely to satisfy an obsolete delayed-callback assertion. The abort timer itself is not modified.
- The later adjacent tongue crossfade is checked for complementary alpha, adjacent-only frames and clamped endpoints rather than reverting to opaque-base stacking. This also agrees with the unchanged `test_tongue_is_real_adjacent_frame_crossfade` contract.
- Existing device rows remain placement labels, not an automatic unassessed patency diagnosis. Tests preserve NPA/OPA/iGel and other findings, idempotent ETT labeling, head-only insertion and dead-patient visibility. The separate Check Airway action is not modified.

One previously passing historical test, `test_hover_selects_shared_slot`, explicitly required the obsolete shared-slot alias. Its identity is retained, but its assertion now verifies separate tube/seal shadows. It is not counted among the seven resolved failures. Only these eight intended existing test bodies change; other test bodies in the affected modules are retained.

## Verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 246 | 239 |
| Passing tests | 2,886 | 2,966 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

The identity-based comparison finds **seven existing failures now passing, zero newly failing identities, zero comparable passing outcomes regressing, and no previous outcome identities missing**. Both broad runs return exit code 1. The remaining 239 failures are not waived, skipped or marked harmless.

The focused suite passes **930 tests plus 400 subtests**, with no failures, errors or skips. It preserves the previous 849-case set and adds 73 new execution cases and the eight selected historical checks. Full-project `hemtt check` returns **0**, with its seven existing non-blocking style suggestions unchanged.

A controlled unchanged-source run copies only the two new test modules onto the original worktree: **16 failed and 57 passed**. Those same **73 cases all pass** against the corrected candidate. Eight failing cases expose the tray defects and eight expose the reflex-boundary disagreements. No production source is changed in the old-source control.

The complete-tree and existing-test AST checks preserve unrelated runtime/assets and unrelated test bodies. No files are deleted. No new skip filter, xfail marking, outcome manipulation or broad reversal of current behavior is used. The evidence ledger retains all 460 original identities and the current 194-entry unresolved source-contract index.

## Execution boundaries and release checks

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Controls, inventory queries, permissions, effect-vector inputs, localization, object identity, sound, placement transport and selected random draws are explicit fixtures. Native airway writes, reflex calculation, receipt/epoch validation, selection scopes and UI state logic execute from the checked-out source. The UI adapter records properties rather than rendering controls. Random draws select test branches; their real distribution is not validated. Only finite-input cases are claimed for the existing finite/linearConversion stand-ins. Namespace comparisons adapt engine object identity without changing the intended identity relation.

No Arma client or dedicated server ran. The tests do not certify real network ordering, rendered alpha/geometry, live inventory replication, downstream medication kinetics or every deferred-event interleaving. In particular, abort tests cover its existing display/patient guard, not a new same-display epoch or generation guard.

A gameplay rebuild is required for the four runtime changes. Live checks should select tube/seal after permission or stock changes, confirm that only the held slot shows its shadow, put down the last consumed tool, and repeat tube passage/manipulation with reactive, sedated, paralyzed and dead patients. Confirm that excluded reflex events do not restart physiology while interaction remains available. Do not pop the old stash or rerun superseded patch installers over this source.

## Independent clean-checkout verification

GitHub Actions run **35799477247**, job **106986269570**, independently verified candidate **cd8d553610985f1bd06f3e52139790206f227d4a**, parent **f44efd601cad1f0f47c5f0bb28a37a9d42731ace**, and complete tree **d5c450ec3f2a393ff9c1ca26edfcd76cf7485917**. The transferred payload and reviewed patch matched their expected hashes; the patch SHA256 is **1031de20e0f68a49ed489583bea28b1d36a50b110ab40b1c35faaa2fda091913**. No candidate source was changed to satisfy the independent run.

The focused suite independently passed **930 tests plus 400 subtests**, without failures, errors or skips. Full-project HEMTT returned **0**. The complete before/after historical runs matched the table above, with **seven previous failures now passing, no newly failing identities, no comparable passing-outcome regressions, no missing prior outcome identities, zero collection/setup errors and four unchanged skips**. Both broad-suite commands still returned **1**; successful audit validation is not a clean broad-suite result.

The unchanged-source control independently produced **16 failed and 57 passed**; the same **73 cases all passed** on the candidate. Exact-tree and AST checks restrict the candidate to **12 added/modified paths**, including the four runtime files and eight intended historical test-body updates. All **4,015 other existing paths remain unchanged**, with **no deleted files**. The audit workflow and transferred payload are not in the production candidate. The follow-up changes only this report to record the independent results.

Raw commands, return codes, before/after outcome streams, JUnit results, reviewed patch, test-edit scope, preservation proof and candidate identity are retained in artifact **10725182632**, `historical-backlog-batch6-results`, SHA256 **004f9746b864d32b49d567f710697489af7c0da244d89ce79fc0ead130a8b4ee**. The evidence package preserves the complete **460-outcome ledger** and **194-entry unresolved original source-contract index**.
