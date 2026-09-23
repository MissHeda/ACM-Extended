# Historical backlog, batch 13: weapon preflight and one-shot holster ownership

## Source and change boundary

Starting published commit: `1ae25330a9d1d77752e8054e022c50ab9637030f`, complete tree `684f8500efe0b96261df4ed40aa29c09dae7d847`. The connected GitHub reference was read before editing. The retained complete tracked-text snapshot and binary assets were verified against their original manifest, then the published Batch 11 and Batch 12 patches and final reports were applied. The reconstructed checkout matches the complete starting tree. A separate unchanged worktree supplies the baseline and red control. Local reconstruction commits are not represented as the original remote commit history.

Only one runtime function changes: `fn_medicAnimationPrep.sqf`. Its nested pending-holster exit is moved to function scope. The runtime diff adds nine lines and removes seven. No animation state, weapon-away implementation, patient treatment, native action eligibility, medication, inventory, renderer, configuration, network message, helper registration or worker changes. The existing 3.2-second reservation window, 0.95/0.70-second minimum settle values and 0.05-second minimum pending return are preserved.

## Confirmed defect

The helper promises one engine weapon-away request while the original request settles. Its pending-reservation branch instead used `exitWith` inside an `if ... then` block. That returned from the inner block but execution continued through the remainder of the helper. When the logical weapon was still selected, another caller could issue another weapon-away request and replace the timestamp. It also failed to return the calculated remaining settle interval.

The correction calculates the same elapsed time and checks the same window, but exits the helper before the second weapon-away path. Ready empty hands still take the existing immediate path. Logical empty hands with an unfinished visible holster still wait. An expired reservation or reversed clock permits the existing fresh-request behavior. The captured original weapon still chooses the same minimum settle value; nothing is retuned.

Nine unchanged-source cases reproduce this defect: six repeated-call combinations across pistol/rifle/launcher and ACE-versus-engine fallback, plus three real treatment-pose handoffs across those weapons. The handoff cases execute the actual pose start and stop functions together with the actual preparation helper. Their failures record repeated engine requests and replaced reservation state, not proof of a particular visible live-game holster loop or lost treatment.

## Historical outcomes resolved

Seven original failures now pass: **H180, H192, H202, H331, H354, H356 and H368**. They concern one-shot weapon preparation, its native/optional-addon boundary, readiness sequencing, timeout behavior and transition priority. All seven are in the original remaining source-contract subset, reducing it from **158 to 151**. Original 448-outcome accounting becomes **276 passing and 172 failing**. The original seven collection errors and five setup errors remain separately recorded as resolved.

Only the selected seven test bodies in six existing historical modules change. Their identities remain unchanged. Old assertions required TSP sling callbacks, obsolete short sling timers, direct `selectWeapon ""` in the generic helper, old callback variable names, or a single preflight wait. The current implementation uses ACE's weapon-away function with its engine fallback and sequential visual-holster/crouch waits. Tests verify that behavior rather than restoring an old integration or timing rule.

One important exception is retained: an already-established Direct Pressure treatment handoff clears logical weapon selection without replaying a holster. A blanket ban on `selectWeapon` in the pose-start function would incorrectly demand removal of that existing path. It is explicitly tested and is not modified. The helper, generic treatment bridge and pose-stop function do not directly reselect or restore a weapon. Other head-position, menu and third-party animation paths are outside this batch's clearance.

The protected snapshot for the single modified function is explicitly updated from `77674cf212e864337dbac3ae174fc45823b0422c7fca9d1a740bbc34cec37764` to `8ec6effab7e90d973a16331ad9cd441de0f7e1f7faf6d26a894f9e9945268175`. All other protected snapshots remain unchanged.

## Execution coverage

The 57 new checks execute the actual preparation helper, full generic treatment bridge, and selected real pose handoffs with explicit engine boundaries. They cover:

- Original-provider reservation reuse, independent provider reservations, valid ready states, visible/logical mismatch, expiry, clock reversal, short/unrelated reservation records, and dead/nonlocal/vehicle provider exclusions in the preparation helper.
- The exact engine fallback command and ACE path while optional sling callbacks are present but must not be called. No new addon dependency is introduced.
- Logical weapon and visible skeleton agreement before crouch, exact existing stand/prone transitions at priority one, native argument preservation, scoped bypass consumption, and the unchanged 3.0/1.8-second sequential timeout values.
- Timeout without clinical launch, superseded-token rejection on both success/timeout paths, life/locality rechecks, and second-phase weapon/visual/stance readiness loss.
- Native BVM variants, stethoscope, head-tilt and CPR launchers bypassing generic preflight; ordinary ready-crouch treatment remaining available for dead patients; native rejection returning unchanged; and repeated click suppression.
- The original Direct Pressure handoff retaining its clinical hold while retiring its visual loop, and actual assessment-to-assessment handoffs sharing the pending holster.

The native treatment itself is a recorded boundary call. These cases do not certify its downstream inventory debit, medical outcome or rejection reasons. Chest physical preparation is configured absent in the generic-bridge fixtures, so its separate carrier/roll path is not tested by this new module. Other existing focused tests remain active.

## Validation results

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 187 | 180 |
| Passed tests | 3,579 | 3,643 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

The identity comparison records seven existing failures now passing, no newly failing identities, no comparable passing-outcome regressions and no missing previous identities. Both broad commands still return 1. The remaining 180 failures remain open; they are not waived, skipped or assumed harmless. The four existing skips, including unbuilt release-package checks, remain unchanged.

The focused suite passes **1,607 tests plus 400 subtests**, without failures, errors or skips. It retains the prior 1,543-test selection and adds 57 new cases and the seven refreshed historical identities. The same 57 new cases copied onto the unchanged source give **9 failed and 48 passed**; all **57 pass** on the correction. Full-project `hemtt check` returns **0** with seven existing nonblocking style suggestions unchanged.

The candidate has eleven added/modified paths: one runtime function, six historical modules, one new execution module, the one scoped preservation digest and two audit documents. No files are deleted. All 4,034 other existing paths remain unchanged. No global test monkeypatch, xfail waiver or new skip filter is introduced.

## Boundaries and release status

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. Weapon selection, visible animation state, stance, vehicle/locality/life state, configuration values, native treatment and callback scheduling are explicit fixtures. Holster requests are recorded while weapon selection stays unchanged to represent a pending engine transition. Callback success is delivered only after its actual condition returns true; timeout is delivered explicitly. This does not simulate elapsed engine animation or a complete CBA scheduler. Existing argument and reservation checks execute from source.

An initial test-only blanket weapon-selection ban was narrowed to avoid incorrectly rejecting the existing DP handoff. An exact timeout-boundary test now starts its clock at zero so subtraction roundoff is not mistaken for a production threshold change. Neither fixture adjustment changes the runtime policy. The final unchanged/corrected control uses identical test files.

No Arma client or dedicated server ran. The tests do not certify live handgun-model clearance, RTM animation timing, every controller-acquisition race, player-control switches, or downstream treatment behavior. No release PBO was built or approved in this batch. This is **not stable-release sign-off**.

A rebuild is required for the one runtime function. In game, begin an assessment with a pistol/rifle/launcher selected, hand off promptly to another pose-controlled assessment, and confirm the pending weapon-away action is not restarted. Then verify ordinary crouch entry, timeout/retry and the existing DP and BVM/CPR paths. Keep the old stash and do not reapply superseded patch installers.

## Independent clean-checkout verification

GitHub Actions run **35821220734**, job **107053272126**, independently verified candidate **9d2e705571242f671751f85da107a7c499462a48**, parent **1ae25330a9d1d77752e8054e022c50ab9637030f**, and complete tree **84fb650ab879ed4e0e79a27d37e682f22050e9dc**. The reviewed patch matched SHA256 **efd93e06339f73bb04f70580b1d422b389120d95dccb0715743e006814cca5a0**. No candidate source was modified to satisfy the independent run.

The focused run independently passed **1,607 tests plus 400 subtests**, without failures, errors or skips. Full-project HEMTT returned **0**, with the same seven existing nonblocking suggestions. Complete historical runs reproduced **187 failed / 3,579 passed** before and **180 failed / 3,643 passed** after, with **5,518 passing subtests**, zero collection/setup errors and the same four skips in each. All seven resolved identities matched the selected tests; no newly failing identities, comparable passing-outcome regressions or missing prior identities appeared. Both broad commands returned **1**. Successful validation is not a clean historical-suite result.

The independent unchanged-source control reproduced **9 failed and 48 passed**; the same **57 cases all passed** on the candidate. Only the new test module was copied onto the old runtime. Exact-tree, runtime-scope, snapshot and AST checks restricted the candidate to eleven intended paths, the one preparation helper and seven selected historical test bodies. All **4,034 other existing paths remained unchanged**, with no files deleted. The one affected preservation digest was updated explicitly; every other protected digest remains unchanged. The temporary validation workflow and payload are not part of the production candidate. The follow-up changes only this report to record these independent results.

Raw command lines and exit codes, before/after outcome streams, JUnit results, reviewed patch, test-edit scope, preservation proof and candidate identity are retained in artifact **10733138212**, `historical-backlog-batch13-results`, SHA256 **2f5899c670ca58e0eb4434071c80541ed0d4a199de64a14d29c43c5876b43e4e**. The evidence package retains all **460 original identities** and the **151-entry unresolved original source-contract index**. The original 448 failures are now 276 passing and 172 failing. No Arma client, dedicated server or stable-release package was run or approved.
