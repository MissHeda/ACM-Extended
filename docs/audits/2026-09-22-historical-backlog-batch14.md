# Historical backlog, batch 14: chest cleanup permission and viewer generations

## Source and scope

Starting published commit: `ac215faa83917e38518b270d44e4d6f96366dad7`, complete tree `1be4a0e02a848a852cbf76a04b04f5ad0179cc21`. GitHub already contained the completed Batch 13 weapon-preflight correction when this continuation began. A fresh pinned tracked-text snapshot, its raw commit and complete manifest were combined with hash-verified retained assets. All 4,045 tracked paths and the exact starting tree matched before editing. An unchanged worktree supplies the baseline.

Only two runtime functions change: `fn_chestSealPatientEnd.sqf` and `fn_chestAccessVestRestore.sqf`. The shared physical-roll authority, roll primitive, provider animations, initial carrier acquisition, clinical eligibility, inventory restoration algorithm and UI renderer are not rewritten. No animation timing, priority, medication, physiology, equipment-consumption rule, registration, event protocol or polling worker is added or retuned.

## Confirmed defects

### A denied physical roll could still force an unconscious rest pose

The common carrier-restoration function asked `chestSealCanPhysicalRoll` for permission. Its false branch nevertheless sent an unconditional `ace_common_switchMove` to `ACM_LyingState`. The chest workspace's separate final-rest helper similarly checked only alive/local/vehicle status before forcing the pose. Thus an ordinary conscious prone casualty, including one with stale procedure-grounded or logical lying bookkeeping, could be seized into an unconscious-looking pose on close.

The common function now retains its existing next-frame gear-restoration path without that forced movement. The workspace rest helper now consults the existing physical-roll authority before sending its rest pose. A denied roll is not overridden by a second, less restrictive path. A positive authority result retains normal front/supine normalization. The eligibility definition itself is unchanged: ordinary prone stance or obtundation alone does not grant physical control.

Twelve unchanged-source cases reproduce the two entry paths with/without a saved carrier. A further case reproduces wake/eligibility loss while a delayed workspace restoration is pending. Saved carrier contents still return through the existing logic, and dead-patient cleanup remains available without restarting a physical animation. These are recorded script-issued pose requests, not a live-game claim that the medical unconscious flag changed.

### An old closing callback could reposition a reopened workspace

Workspace finalization and carrier restoration already had generation checks, but several delayed success/timeout paths called the front-rest helper before reaching those checks. After a new viewer joined and advanced the generation, the old callback could therefore write the newer side cache and request a pose before its later finalization was rejected.

The existing generation is now passed explicitly to the front-rest helper at each of its eight call sites. That helper rejects a different generation or nonempty current viewer-token list before changing either side or pose. All payloads already carried the generation; no new persistent field or network message is introduced. Four old-source cases reproduce stale roll completion, carrier completion and timeout delivery after a new viewer joins. The existing busy-wait success path is a passing control.

Normal final-viewer cleanup, intermediate-viewer departures, unknown tokens, carrier contents, legitimate supine exit and the existing Semi-Fowler resume handoff remain covered. Callback durations and the reverse carrier choreography are unchanged.

## Historical work resolved

Five original failed identities now pass: **H157, H191, H211, H367 and H388**. All five are in the previous 151-entry unresolved original source-contract subset, reducing it to **146**. Original 448-outcome accounting becomes **281 passing and 167 failing**. The original seven collection and five setup errors remain separately recorded as resolved in the complete 460-outcome ledger.

The five selected historical test bodies retain their identities. Their assertions now exercise current owner routing, physical permission, explicit procedural-view state and the scoped animation-graph repair. The original roll function remains byte-for-byte unchanged: it requests priority one, then permits its existing 0.15-second priority-two fallback only if the same valid token still owns an unstarted transition. The old blanket priority-two prohibition and continuous geometry-driven canvas reclassification are not restored to satisfy historical text.

A separate previously passing root-level supine test explicitly required the unconditional fallback that is being removed. Its single assertion is replaced with a check of the final, permission-guarded rest path. That update is not counted among the five resolved backlog failures. The two affected runtime snapshot digests and that root test's digest are updated explicitly; every other protected digest remains unchanged.

## What executes

The 74 new cases execute the actual roll-permission helper, workspace begin/end, carrier restore, physical roll, virtual Flip branch, anatomical-surface reader and the current canvas-lock fragment. Inventory primitives, animated surface samples and selected presentation delegates are explicit fixtures rather than game objects. The real branch ordering, generation/token guards, saved carrier payload, requested priorities, callback payloads and eligibility reads remain in the executed SQF.

Conditional callbacks are delivered only after their actual condition succeeds; timeout delivery is explicit. Selected scheduling orders are replayed rather than simulated as a complete CBA scheduler. The tests cover ordinary conscious prone, stale lying/grounded flags, actual unconsciousness, known recovered lying poses, vehicles, locality loss, death, unaffected viewers, actual current-generation joining, missing/retained carrier, normal and stale delayed paths, head-resume handoff, roll fallback and token invalidation.

The anatomical-side cases substitute world-space selection coordinates at the engine boundary and execute the actual cross-product/classification arithmetic. The canvas cases execute the actual explicit endpoint block and confirm that expiry does not reclassify from transient geometry. This does not render an RTM, control or hitbox. The physical-roll driver and UI renderer themselves are unchanged.

## Validation results

| Historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 180 | 175 |
| Passing tests | 3,643 | 3,722 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skips | 4 | 4 |

Identity comparison records five previous failures now passing, no newly failing identities, no comparable passing-outcome regressions and no missing previous identities. Both broad commands return exit code 1. The remaining 175 failures are open, not waived or marked expected-failure. Existing release-package skips remain unchanged.

The final focused selection retains the prior 1,607 tests, adds 74 new cases, the five selected historical identities and 44 relevant root-level chest contracts: **1,730 tests plus 400 subtests**, with no failures, errors or skips. Full-project `hemtt check` returns **0**, retaining the seven existing nonblocking style suggestions. Those suggestions are not changed.

The same 74 new cases copied onto unchanged runtime produce **17 failed and 57 passed**; all **74 pass** with the correction. Seventeen is a regression-case count, not seventeen different gameplay defects. Exact source and test-body checks permit only the two runtime functions, the five selected addon tests, the one root test, their scoped preservation digests, the new execution module and audit documentation. No files are deleted.

A separate broader root-level chest probe still has one inherited collection failure in `test_fork_phase150_flip_cancel.py`, which demands an obsolete one-argument patient-roll-cancel call. With collection continuation, its other 44 tests pass both before and after the reviewed supine-assertion update. That existing collection failure is outside the historical addon-suite counts and remains open; it is not hidden by a new skip or changed production call.

## Boundaries and release status

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Object identity, life/locality/vehicle state, visible animation, inventory/loadout primitives, world-space selections, timing and network presentation are explicit fixtures. Finite-input/map-default substitutions retain the existing test harness's stated limits. The tests record requested movements rather than making actual players move.

This batch does not certify generation-counter reuse across full heals, old initial-readiness callbacks, all interruptions of an already-running carrier lift, unrelated stethoscope display leases, or every owner-away-and-back interleaving. It does not clear the entire chest lifecycle or release backlog. No Arma client, dedicated server or final release PBO was run or approved. This is **not stable-release sign-off**.

A rebuild is required for the two runtime corrections. In game, compare chest-workspace close on an unconscious casualty with an ordinary conscious prone player, with and without carrier custody. Close/reopen while the old restore is waiting or completing, and confirm the old completion does not reposition the new workspace. Verify normal supine exit, Semi-Fowler restoration and dead-patient gear handling remain intact. Keep the old stash and do not rerun superseded installers.
