# Historical backlog, batch 12: provider-pose cleanup and frozen-hold contracts

## Source and scope

Starting published commit: `c7fc94d1501ab4acee0dde86fc60caa48cba5f33`, complete tree `18b304f758cc3c2d65294f317c33df60b3665a1e`. The connected GitHub reference and commit tree were read before editing. Retained tracked-source and binary archives were checked against the pinned manifest, the published Batch 11 patch and its final report. The reconstructed checkout matches that exact complete tree. A separate unchanged worktree supplies the baseline and old-source control.

Only **one runtime function changes**, `fn_treatmentPoseStop.sqf`: one guard and its explanatory comment, two added lines. The existing provider-stance ownership helper is reused. No animation state, move priority, freeze sample, callback delay, controller duration, configuration, clinical state, medication, inventory, rendering or network protocol changes. No new helper registration, timer, worker or event is added.

## Confirmed cleanup race

The existing normal exit requests a neutral crouch and schedules a one-shot correction 0.12 seconds later. That correction checks whether the ended treatment's epoch still matches and whether its pose state is empty. Several other provider controllers can acquire stance without incrementing that treatment-pose epoch. Consequently, the old correction could issue a stand-to-crouch animation and schedule further stance cleanup underneath a newly active controller.

The final 0.85-second stance-release callback already used `ACME_fnc_providerStanceOwned`; the earlier correction did not. The correction now uses the same helper before changing stance or requesting a move. It returns when another provider controller owns the action. Ordinary unowned cleanup retains the same crouch correction and final AUTO release. The intentional handoff callbacks and their existing delays are unchanged.

Eleven old-source cases reproduce the conflict with current ownership markers for preflight, native treatment, roll, head positioning, medical-menu pose, raising/holding a bag, Direct Pressure, its treatment handoff, CPR and a player-bound continuous action. Those markers are evaluated by the **actual ownership helper**, not a stub that simply returns true. The full actual stop function schedules the callback; the tests then model a new controller acquiring ownership before delivering it. They record a stale animation/stance request, not a demonstrated live multiplayer animation failure. They do not claim all interleavings or every controller's acquisition path are simulated.

The corrected callback issues no move or stance request and creates no successor callback in those cases. Normal cleanup, wrong-mode/wrong-epoch rejection, duplicate stopping, death/unconsciousness/vehicle/locality guards and the later/handoff cleanup paths remain tested. This is one missing ownership gate, not a replacement stance system.

## Historical contracts resolved

Ten previously failing identities are updated without renaming or removing them. Six belong to the original 164-entry unresolved source-contract set: **H177, H178, H201, H207, H208 and H210**. That set decreases to **158**. The other four are B31 treatment-animation tests exposed by Batch 1's collection repair; they are not subtracted again from the original set.

Original 448-outcome accounting becomes **269 passing and 179 failing**. The original seven collection and five setup errors remain separately retained as resolved in the 460-outcome ledger.

Only the ten selected historical test bodies in four existing modules are changed. Their old expectations demanded retired all-looped inspection wrappers, old weapon-family names, old inline callback tuples, an obsolete pulse hold of 0.691 seconds, and a freeze-before-seek order. The replacement checks follow the current native-speed controller, current per-mode hold table, finite/looped wrapper distinction, and final freeze after seeking. No production animation was reverted to satisfy a historical string.

The source-preservation test's digest for the one modified function is updated explicitly. Every other protected digest remains identical. This is not a blanket regeneration of snapshots: the complete runtime diff is the stated ownership guard plus comment, and independent validation checks that exact replacement.

## Execution coverage

The new module runs the actual treatment-pose start/stop functions and observer receiver with explicit Arma/CBA boundaries. Cases cover:

- Queued entry cancellation at all six controller stages, scoped fatigue-exclusion/JIP cleanup, deleted providers and stale owner ticks.
- Current roll/chest-access/inspection and pulse/stethoscope sample times despite a late observing frame, known-duration and unknown-duration fallback, single finite-action entry, crouch-first transition and speed-only versus state drift.
- Owner hold reception without a second seek, observer seek followed by the final freeze, duplicate packets without extra observer workers, atomic-episode waiting, late holds after release/new episodes, and observer retirement after death, unconsciousness, vehicle entry, ownership transfer or episode end.
- All existing ownership-marker categories during delayed correction, final stance release and intentional handoff cleanup, plus ordinary free cleanup retaining its bounded timing.

Six source-config checks retain the current work-state parents, finite/looped flags, weapon restrictions and authored exit connections. Config parsing is source-level evidence; the complete config is separately compiled by the retained HEMTT checks. Actual RTM rendering or game-engine interpretation of duration/phase is not certified by these arithmetic and command-recording tests.

## Local validation

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 197 | 187 |
| Passed tests | 3,468 | 3,579 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

The identity comparison finds **ten previous failures now passing**, no new failing identities, no comparable passing-outcome regressions and no missing previous outcome identities. Both broad commands return exit code 1. The remaining **187** failures are open, not waived or marked harmless. Existing four skips remain unchanged, including release-package checks that still require a built package.

The focused suite passes **1,543 tests plus 400 subtests**, with no failures, errors or skips. It retains the prior 1,432-case selection and adds 101 new checks plus the ten selected historical identities. The same 101 new checks on the unchanged source give **11 failed and 90 passed**; all **101 pass** with the correction. The eleven failures are the reproduced earlier-callback ownership conflict. Full-project `hemtt check` returns **0**; its seven existing nonblocking suggestions remain unchanged.

The candidate has nine added/modified paths: one runtime function, four historical test modules, one new test module, the explicitly scoped preservation digest and two audit files. All **4,034 other existing paths remain unchanged**, and no files are deleted. No skip/xfail waiver, global test monkeypatch or outcome manipulation is introduced.

## Boundaries and release status

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. The test fixture explicitly supplies stance, animation state, duration/phase, locality, vehicle state and callback delivery. It records movement/speed/JIP/stance commands instead of rendering or broadcasting them. Map-default reads use an equivalent default lookup on actual VM maps. Startup tables come from the checked-out initializer. Control markers use namespace stand-ins for Arma objects. Two early test-fixture issues (a mock log variable shadowed by the production JIP ID and a transition fixture still reporting crouch idle) were corrected in tests only before the final old/new control.

CBA documents `waitAndExecute` as a delayed, one-shot unscheduled callback; the guard must be evaluated when it executes. Bohemia documents `setUnitPos` as stance rules rather than a direct human-player posture change. The reproduced conflict includes the actual queued animation request, not a claim that `setUnitPos` alone visibly moves a player. No gameplay parameter was changed based on external documentation.

No Arma client or dedicated server ran. Live RTM phases, keyboard/treatment event timing, rendered freezes, network ordering, and complete new-controller acquisition/cancellation remain outside these tests. Other chest/stethoscope teardown paths were not rewritten or cleared by this batch. This is **not stable-release approval** and does not close the existing release-package testing gap.

A rebuild is needed for the single runtime guard. In game, end a pose-owned assessment and promptly begin a different provider action, including Direct Pressure, BVM/CPR, Hang Bag or a head-position sequence. The old callback must not request a second crouch over the new action. With no replacement action, normal crouch exit and freedom to change stance must remain. Keep the old stash and do not reapply superseded installers.

## Independent clean-checkout verification

GitHub Actions run **35818391984**, job **107044784334**, independently verified candidate **29e72b09ea53e1c0defaf438a998b1f34f1ba4fe**, parent **c7fc94d1501ab4acee0dde86fc60caa48cba5f33**, and complete tree **385ad6b8ec1734d752ce66ee7e850cd4f31b6050**. The complete reviewed patch matched SHA256 **455b629d8e48af106bd264fdf7f949b30daae0f4299c30d72230481589eea876**. The candidate was not modified to satisfy the independent run.

The focused run independently passed **1,543 tests plus 400 subtests**, without failures, errors or skips. Full-project HEMTT returned **0**, retaining the same seven nonblocking suggestions. Complete historical runs reproduced **197 failed / 3,468 passed** before and **187 failed / 3,579 passed** after, with **5,518 passing subtests**, zero collection/setup errors and the same four skips in each. All ten resolved identities matched the selected tests; no newly failing identities, comparable passing-outcome regressions or missing prior outcomes appeared. Both broad commands still returned **1**. Successful audit validation is not a clean broad-suite result.

The independent old-source control reproduced **11 failed and 90 passed**; the same **101 cases all passed** on the candidate. Only the new test module was copied to the old worktree, leaving its runtime unchanged. The eleven failures all belong to the earlier-callback ownership cases. Exact-tree, runtime-replacement and AST checks restricted the candidate to nine intended paths, the single ownership guard and comment, and ten existing historical test-body changes. The one affected preservation digest was explicitly updated; all other protected digests and all **4,034 other existing paths remained unchanged**. No files were deleted. Temporary audit workflows and transfer payloads are not part of the production candidate. The follow-up changes only this report to record these independent results.

Raw command lines and exit codes, before/after outcome streams, JUnit results, reviewed patch, preservation proof and verified candidate identity are retained in artifact **10732547606**, `historical-backlog-batch12-results`, SHA256 **58f46835d6b924cbc280d1f3d5fa578f03de7c3aea754acace23bf79c115d9f4**. The evidence package retains all **460 original identities**, the **158-entry remaining original source-contract index**, and the four separately tracked newly-exposed B31 resolutions. No Arma client, dedicated server or stable-release package was run or approved.
