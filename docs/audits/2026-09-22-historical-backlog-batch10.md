# Historical backlog, batch 10: carousel navigation and keyboard ownership

## Source and scope

Starting commit: `125dd48d6a4d463ce9e5fe87368385a5fdf52c2d`, complete source tree `1e8e9fe4dc78980c0d6fe48c3ea831e932436510`. GitHub confirms the user's Batch 9 push. The complete local checkout was reconstructed from the retained source/assets and published patches, then matched to that exact tree before editing. An unchanged separate worktree supplies the historical and red-control baseline.

Four runtime files change: `fn_skCarouselPick.sqf`, `fn_skCarouselMove.sqf`, `fn_skInject.sqf`, and `fn_skUiTick.sqf`. The runtime diff is 20 added lines and 10 removed lines. No configuration, asset, medication, inventory ledger, patient-state, animation, font, geometry or rendering algorithm is changed. No polling worker, event type, new registered helper or network request is added. Existing A/D initial delay (0.22 s), repeat interval (0.09 s), and collapse/hover settings remain unchanged.

## Reproduced defects and necessary corrections

### Outer-slot clicks left an old navigation callback behind

The move and renderer already use immediate selection/presentation, but an outer-slot click still split into two moves separated by an old 0.24-second callback. That callback retained only its direction. It could therefore change whichever display/provider/selection existed when it ran, including a reopened dialog or a later manual selection. A rejected first move could also leave a callback which became eligible later.

The click now asks the existing move function for one or two steps in a single transaction. The new optional step argument defaults to one, preserving all existing A/D callers. An outer click resolves its final index immediately and performs one layout/render/hotspot refresh, rather than temporarily selecting an intermediate medication and leaving a second navigation callback. The obsolete 0.24-second outer-click delay is intentionally removed; the current immediate renderer is not replaced with a new animation or timing system. Center-click toggle/staged-target behavior and empty/single-store behavior are retained.

This establishes selection-state defects, not a reproduced medication administration error. Drug delivery itself is not changed or tested by these cases.

### A browsing hold could continue during or after another UI workflow

The repeat tick did not recheck control focus, so an already-held A/D direction could continue to navigate while an edit control owned focus. KeyUp also returned early in non-text tag mode before clearing the held direction. Ending that editor could revive a key that had already been released. A closed display could similarly miss its final KeyUp, and a new display did not reset the global hold before opening straight to Body Map.

The existing repeat tick now clears the hold and repeat deadline when tag editing, any CT_EDIT control or a busy injection owns input. KeyUp can release a hold in tag mode without consuming text-edit events. The existing per-display initializer clears the two hold fields before selecting its opening view. No new timer or per-field input exception is added. New-display initialization does not clear or recreate an ongoing Hardcore medication-push job.

The tests also cover ordinary initial navigation, engine duplicate KeyDown, held repeat, release, unrelated keys, selected-view routing and the legacy body's thin navigation delegate. Live keyboard dispatch and player switching are explicit test boundaries, not an Arma simulation.

## Historical tests resolved

Twelve previously failing identities now pass: **H219, H230, H238, H240, H244, H254, H277, H278, H324, H365, H379 and H384**. Ten are in the original unresolved source-contract subset, reducing it from **174 to 164**. H277/H278 were separately diagnosed obsolete motion/nudge expectations, not part of that subset.

Across the original 448 failed outcomes, **263 now pass and 185 remain failing**. The original seven collection and five setup errors remain recorded separately as resolved. The complete 460-outcome evidence ledger retains each original identity; no old outcome is silently deleted.

Only those twelve existing test bodies change. Their IDs retain older historical wording, but their contracts now follow the approved single tandem Body Map, immediate renderer and presentation-only hover. The old 0.085-second interpolation, decorative single-syringe nudge, separate standalone page and hover-driven expansion are not restored merely to satisfy assertions.

Source-derived slot arithmetic verifies that current hover alpha changes do not change the same slot's geometry. Actual plunger arithmetic uses drug plus carrier volume and remains clamped to the barrel. These calculations use explicit fixed viewport inputs, not rendered controls. The renderer itself is byte-for-byte unchanged. Retention tests cover pointer/zone hover, tag focus, color dropdown, held browsing keys, staged administration, dedicated editing, the existing busy state and ordinary expiration. Navigation preserves stored contents and clears only its existing dose/site/flush/discard transients.

## Verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failed outcomes | 218 | 206 |
| Passed tests | 3,215 | 3,324 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Identity comparison records **12 existing failures now passing**, **zero newly failing identities**, **zero comparable passing outcomes regressing** and **no prior outcome identities missing**. Both broad runs return exit code 1. The remaining 206 failures are open, not waived or marked expected-failure. The four existing skips are unchanged.

The focused suite passes **1,288 tests and 400 subtests**, with no failures, errors or skips. It retains the prior 1,179-case selection and adds **97 new cases** and the twelve refreshed historical checks. Full-project `hemtt check` returns **0**, with the same seven non-blocking style suggestions left unchanged.

The unchanged-source control copies only the new test module onto the original worktree: **31 failed and 66 passed**. The same **97 cases pass** on the corrected source. Nine failures expose stale/deferred selection, and 22 expose focus, release or new-display hold ownership. No production code changes in the old-source control. Earlier adapter-only failures (a duplicate source anchor and unsupported viewport primitive) were corrected in the test adapter, not production, before this final control.

The complete-tree, runtime allowlist and existing-test AST checks preserve other runtime files, assets and unrelated test bodies. The candidate contains **16 added/modified paths** and **no deleted files**. No global test monkeypatch, xfail waiver or added skip filter is used.

## Boundaries and release checks

Toolchain: HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. The new cases execute the actual store identity functions, move/pick/hover/toggle functions, extracted actual KeyDown/KeyUp bodies, display initialization, and complete initial repeat/collapse tick section. Stock refresh, plunger dragging and NV work later in the tick are outside this new module's scope and remain covered only by their existing tests. Controls, viewport height, focus, presentation delegates and callback delivery are explicit fixtures. Test callbacks are replayed in selected orders; scheduling latency is not emulated. Geometry and fill fragments run arithmetically but are not rendered.

No Arma client or dedicated server ran. This does not certify live hitbox placement, alpha/font rendering, every key/focus event order, real player-control handoff, downstream administration, or other asynchronous preparation/tag-focus callbacks. Unrelated animation, medication and UI failures remain in the backlog.

A rebuild is required for the four runtime files. In game, click inner and outer stored syringes, close/reopen immediately, hold A/D then focus tag/seconds inputs, enter/leave Edit Tag, and reopen directly onto a stored syringe after closing with a key held. The intended syringe must remain selected, normal A/D repeat should be unchanged, hover must not expand the view, and a running Hardcore push must retain its existing job. Keep the old stash; do not rerun Batch 9 or earlier installers over this version.
