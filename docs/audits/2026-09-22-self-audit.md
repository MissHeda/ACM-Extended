# ACME preservation and consciousness self-audit

## Scope and provenance

Audited main: `df7c8b31d6715e8144c8948c6eb58f1088c728d9`.
Last complete user-committed baseline: `5dca0429d9ef211f3366cd54b4f3c95274ba7a48`.
Original fork point for the two intentional wake/seizure commits: `cf43be2be4b9d0d741e410d688de4abae3aedbf9`.
Intentional wake/seizure changes: through `d878b60bd03040aae2e2ff6674b1f6e524694339` (29 paths).
The uploaded addons archive was also examined. It contains local intermediate patches, not a complete repository history.

The previous merge was incorrect: its parent list included the user's newer baseline, but its tree was based on the older branch plus only the three NV files. Ancestry alone did not preserve the later code. The comparison found 72 changed/deleted paths outside the intended 29-path wake/seizure change set, including chest access, supine/head-elevated positioning, BVM startup, IV-tray presentation, blood flow, multiplayer seizure rendering and historical regression tests.

The corrective tree starts from the complete newer baseline and three-way merges the 29 intentional paths. Only two content conflicts required resolution: obtundedApply and rocuroniumTick. All other unrelated baseline files are preserved, rather than reconstructed from comments or an old patch script.

## Necessary corrections

1. Restore the lost baseline functions and regression tests. Keep the existing roller-clamp NV fix, chest/stethoscope transitions, patient-position protection, IV-tray fixes, BVM startup grace and server-visible seizure gesture path.
2. Replace the arbitrary 0.15-second low-level wake fallback with one state-aware reconciliation helper. It checks clinical eligibility and accepts only actual CBA states Default, Injured or Unconscious. Unknown states, cardiac arrest, fatal injury and death do not qualify. An Unconscious machine is transitioned through CBA; an already-awake machine may have its stale raw flag repaired. Requests return the observed outcome, not merely that an event was sent.
3. Retain external/native WakeUp event support, with per-request tickets, clinical epochs and owner checks. A new unconscious episode, reset/restore or ownership change invalidates deferred work. Do not change vital signs to make a wake pass.
4. Reject a denied/stale obtundation request at function scope before publishing the state or changing posture. The old nested exitWith did not exit the surrounding function.
5. When the paralytic subsystem is disabled, release only its owned paralysis/apnea/stress channels and ask the shared wake authority to reevaluate. Do not remove medication records or override another unconsciousness cause.
6. Preserve seizure physiology under paralysis but stop the motor presentation on the blockade transition. Retain multiplayer gesture synchronization, prevent stale/reset/foreign-owner starts, and avoid broadcasting repeated empty-session stop events while the patient remains paralyzed.
7. Do not disclose masked cerebral activity through the ordinary injury list. The debug seizure-control display remains available. No EEG or additional diagnostic feature was introduced.

## Intentionally unchanged

No medication dose, concentration, induction/maintenance threshold, absorption/washout curve, seizure-control weight, blood-volume rule, ventilation target, TBI progression rule or animation-speed tuning was changed in this audit. The already-approved seizure-control model remains a gameplay model, not clinical dosing guidance. Reusable/dead-patient equipment handling is not replaced with an alive-only interaction rule. No new UI layout, stance system or all-patient per-frame polling loop was added.

## Verification

The targeted local suite passed **156 tests with no skips**, using HEMTT 1.22.0 and SQF-VM v2026.04.03-ed9f5f5. It includes 68 byte-preservation snapshot cases, source/lifecycle checks, real wake-helper execution with engine/CBA boundaries mocked, BVM startup and cancellation tests, and full Extended-config conversion with HEMTT. One restored BVM test fixture was updated to represent its existing owner-routed breath event and existing stance-owner helper; the BVM implementation itself was not rewritten. Two older sedation assertions were updated to follow the new shared helper rather than require obsolete inline text.

The wake execution cases cover valid/invalid medical machine states, unstable vitals, active sedation, paralysis, active seizure, arrest, surgical/evacuation blockers, traumatic knockout versus a permitted stimulus, repeated requests, owner changes, reset epochs and superseded deferred work.

The broad historical addon suite is **not clean**. Before these audit changes, the newer baseline produced 448 failures and 12 collection errors, with 1,587 passing tests, 151 skips and 2,747 passing subtests (excluding a retired B77 import-time version check that exits collection). Many assertions reference old implementation text or retired layouts. They were not mass-edited or treated as proof that current gameplay needed changing. The two newly changed inline-sedation assertions have been reconciled with the shared-helper contract. This is not a claim that every historical failure has been diagnosed or is harmless.

HEMTT full-project checking in the initial extracted local snapshot stopped because the snapshot-transfer selection omitted the repository's five .inc include files. That result was an incomplete audit fixture, not evidence that the source should be changed. The isolated GitHub validation job uses the complete checkout and records the full-project result separately.

No Arma client or dedicated server was run in this environment. SQF-VM tests mock engine UI/animation/network boundaries; they do not prove rendered pose, live network ordering, sound, or game-engine integration. In-game validation remains required before a release.

## In-game release checks

- Repeat ketamine induction, maintained sedation, rocuronium, reversal and drug washout; test shake/ammonia both while blocked and after genuine eligibility returns.
- Repeat with AI, a remote-owned player and a dedicated server. Heal/reset or transfer ownership while a wake event is pending; old work must not wake a newer episode.
- Induce a seizure before/after blockade, then let blockade and anticonvulsant effect wear off separately. Both observers should agree on motor masking, without the ordinary injury list revealing hidden activity.
- Recheck the previously reported listen-server BVM startup, chest/stethoscope entry/exit, supine/Semi-Fowler positioning, upward-only IV-tray display and NV infusion/roller-clamp sequence.

Do not run the superseded local consciousness/seizure patch scripts over this source tree. Keep the old local stash as a backup until gameplay validation is complete.
