# Historical backlog, batch 7: ECG artifact and junctional progress

## Scope

Starting commit: `0b583737f8542a56fb66ad739c587aaadf3deefd`, complete tree `5a737a28154a86d0aeb1b2f09a2384669637c189`. The connected GitHub head and commit tree were checked first. The complete local checkout, reconstructed from the retained source/assets and published patches, matched that tree exactly. The historical baseline ran separately without source edits.

Only two runtime files change: `fn_ecgArtifactStrength.sqf` and `fn_junctionalStartBleed.sqf`. Both corrections fix a reader using the wrong identifier. No configuration, dose/concentration, medication kinetics, sedation threshold, seizure weight, bleed-rate constant, compensation curve, animation timing, layout, inventory rule, networking loop or worker cadence was changed. Existing treatment progress is repaired, not replaced with a new bandaging feature.

## Confirmed defects

### Suction artifact compared an episode number to the clock

The actual suction writer stores sessions as `[token, provider, expiry, mode, clinicalEpoch, sequence, position, device]`. The ECG artifact reader compared index 4 (clinicalEpoch) to mission time instead of index 2 (expiry). This could omit the existing visual suction artifact while suction was active, or retain it after expiry when the episode number was numerically larger than the current time.

The correction changes the selected index from 4 to 2. No suction physiology, lease duration, artifact magnitude or ECG morphology is changed. Nine old-source cases reproduce the mismatch using records produced by the real suction-state writer across hand, SALAD and manual modes with multiple episode values. The same cases verify the strict expiry boundary and that the visual reader does not mutate session state.

### Junctional packing compared a body part to a transaction key

Inside the packing-progress branch, the outer `_x` represented the junctional body part. The nested HashMap loop reused `_x` for each treatment transaction key and `_y` for its value. Comparing `_bp == _x` therefore compared the recorded body part to the transaction identifier, not the wound being treated. Valid packing progress was ignored until the permanent completion callback changed the wound state.

The correction captures the current body part as `_packingPart` before entering the map loop and compares against that captured value. The existing quadratic progression, completed-gauze multiplier, cancellation behavior and separate blood-volume integration remain unchanged. Eight partial/completed-progress cases and one cancellation case fail before the correction and pass afterward. The primary progress cases use the real native bandage-progress producer, including its normalized body-part names, rather than an invented record shape. The actual stop helper removes temporary progress during the cancellation case.

This does not mean final packing failed, or that every junctional wound drained twice. The defect was in matching an active progress record. The worker continues to publish only its L/s contribution and does not write blood volume directly.

## Historical outcomes resolved

Seven original failed identities now pass: **H015, H018, H021, H040, H076, H077 and H078**. All belong to the original unresolved source-contract subset, reducing it from **194 to 187**. Of the original 448 failed outcomes, **237 now pass and 211 remain failing**. The original seven collection and five setup error identities remain separately tracked as resolved.

The refreshed checks preserve current behavior rather than restoring retired implementations:

- ACE treatment events create/release independent artifact leases. Current minigame initialization and close modules contain their matching artifact keys. The native and custom ECG paths each call the shared artifact boundary once.
- The Kelly panel consumes the same native ECG generator for both windows; it does not need another independent artifact implementation. The panel's existing PEA electrical-rate/mechanical-perfusion separation is exercised.
- PEA retains its current narrow/default and severe-uncovered-burden wide morphology. Tests execute the existing subtype reader and full native ECG generator. No all-wide PEA template or new diagnostic threshold is reinstated.
- Native critical-vitals handling owns VT recovery. The existing Extended threshold observer does not blanket-clear untreated native critical rhythms. Tests execute native recovery boundaries instead of demanding the retired Extended recovery timer.
- Junctional baseline values and the user multiplier are read from their canonical current configuration. The existing isolated reference-model assertions remain, while a separate execution check verifies that the current difficulty branch applies/restores the baseline without compounding it.
- Current wound, gauze, XStat and wrap layers remain visible as appropriate on live and dead patients. Injury labels read the frozen rebleed state rather than advancing its clock. No wound-color or body-map implementation is changed.

Only six selected existing test bodies and the junctional test's numeric-default locator are changed. H077's original reference-model assertions themselves remain unchanged; fixing its source locator lets them execute. Other tests and historical identities are preserved.

## Verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 239 | 232 |
| Passing tests | 2,966 | 3,055 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skipped tests | 4 | 4 |

Outcome-by-outcome comparison records seven previous failures now passing, no newly failing identities, no comparable passing outcomes regressing and no previous outcome identities missing. Both broad runs still return exit code 1. The remaining 232 failures are open, not waived or marked expected-failure.

The focused suite passes **1,019 tests plus 400 subtests**, with no failures, errors or skips. It retains the prior 930-case focused set and adds 82 new execution cases and seven historical identities. Full-project `hemtt check` returns **0**, with the same seven non-blocking style suggestions left unchanged.

A separate old-source control copies only the two new test modules onto the unchanged baseline: **18 failed, 64 passed**. The same **82 cases pass** on the corrected source. Nine failures expose the suction-reader mismatch; nine expose packing-progress matching. The positive controls cover unaffected behavior rather than assuming every new test should fail on the old source.

The evidence retains the complete original 460-outcome ledger, 187-entry unresolved source-contract index, complete source-tree comparison, raw broad outcomes, exact patch and red/green execution results. No tests are mass-skipped, marked xfail or removed to make the numbers improve.

## Execution boundaries and release checks

HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5 execute the checks. Objects, clocks, transport, scheduling, sound and UI controls have explicit stand-ins. Unsupported HashMap iteration is represented as real map keys plus their values, preserving `_x`/`_y` scope; the adapted iteration bodies have no early loop break. Unsupported resize-with-fill and triangular random use equivalent resize/fill and modal values. Only finite numeric inputs are covered by the existing finite/linearConversion fixtures. Large fixture control IDs use exact decimal keys because the VM's generic string conversion rounds them. Random distributions and live visual geometry are not certified.

The full ECG generator and junctional rate worker execute, but downstream native blood-volume integration, a live waveform/sound pair, real multiplayer ordering, sound-source rendering, and full death/owner-handoff scheduling are not simulated. No Arma client or dedicated server ran.

A rebuild is required for the two runtime changes. Live checks should verify suction motion artifact appears/stops with active/expired sessions, and compare junctional flow during valid packing progress, cancellation and completion on the selected versus unrelated limb. Existing waveform morphology, electrical rate and completed-dressing behavior should remain unchanged. Keep the old stash as a backup and do not rerun superseded installers over this source.
