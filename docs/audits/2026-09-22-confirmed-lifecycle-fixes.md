# Confirmed lifecycle fixes, 22 September 2026

## Scope and provenance

This change addresses the four runtime findings from the historical-suite verification, not the entire historical assertion backlog. It does not change medication doses, pharmacokinetics, sedation thresholds, seizure suppression weights, blood-volume conversion, ventilator targets, or animation timing.

Base: `c3dd15f41a56a253461d876b478f91849d23551f`.
Tested production commit: `2c04560cfceb2299622f7e2254916b17b9641e10`.
Tested complete source tree: `d01ae33c9fe24073ea6a590f044b41aa0efeb23f`.
Independent GitHub Actions validation: run `35752687645`, workflow `Confirmed lifecycle validation`.

The production commit is a direct child of the current audited main, not a merge constructed from an older source tree. Its exact diff contains 15 paths, including three new Hang Bag helpers and one new regression-test file, with no deleted files. Existing source/assets outside those paths remain unchanged. This report is a documentation-only follow-up.

The earlier interrupted attempts had pushed only a read-only source-snapshot workflow to a preparation branch. They had not published these runtime fixes to main.

## F01: rejected surgical-airway startup leaves a reservation

Previously SurgicalAirway_InProgress was set before beginContinuousAction accepted startup. A busy controller, dead medic or unconscious medic could reject the action without installing the cancellation handler that would release the reservation.

The reservation is now acquired inside the accepted On Start callback, and the controller receives the head body-part argument. Rejected attempts leave no new reservation. An existing reservation still blocks a second attempt and is not cleared by that rejected attempt. Successful cancellation continues through the original cleanup and kit-return path.

Execution cases cover all three startup rejection causes, retry after rejection, cancellation called repeatedly, and preservation of an already-held reservation. The tests assert one kit-return call; the engine inventory command itself is mocked.

## F02: changing the controlled player leaves the old manual hold active

The continuous controller now records whether its session was started by the locally controlled player. A change of ACE_player cancels that player-bound session on the next controller tick. Old delayed stance callbacks also check that identity.

The old living local provider still receives the original release cleanup, rather than being mistaken for an unusable/dead provider. The controller does not reopen the medical menu for the newly controlled unit. AI/scripted local providers that were not the controlled player at startup remain independent of player selection.

The existing bounded BVM source-dialog startup grace, clinical death/respawn conditions and continuous-action generation checks are retained.

## F03: stethoscope close clears the flip flag before checking it

The close function now captures ACME_stethFlipActive before clearing it. The existing provider-flip and patient-flip cancellation hooks therefore execute for an active flip, using the original front/supine settlement request.

No new chest animation or exit pose was introduced. Repeat close calls do not repeat the immediate active-flip cancellation, and closing without an active flip does not call those hooks.

## F04: two providers can both accept the same Hang Bag hold

The old provider-side start used replicated holder state as an acquisition decision, despite an existing patient-owner command route. The source-supported race was that two providers could both see no holder, both start, and later cancel each other when the competing writes arrived.

Startup now requests an exact provider/episode claim from the patient owner. Arbitration runs unscheduled at that owner. An unexpired claim remains occupied even when the provider's Active publication has not arrived. Only an accepted acknowledgement starts the bag presentation. A rejected or expired pending request unwinds its preparation without touching another episode's props or claim.

The protocol uses the existing Hang Bag tick and owner reconciliation, not a new all-patient per-frame loop:

- Pending requests time out after five seconds.
- Accepted claims are renewed at most once every two seconds and expire after six seconds without renewal.
- Renewals and releases must match the exact provider and episode. Old releases cannot clear newer claims.
- Late or duplicate acknowledgements cannot restart cancelled holds, repeat props, or rewind a newer confirmation time.
- Provider death/unconsciousness, distance, ownership, controlled-player changes, patient clinical epochs, restoration and the Hang Bag system switch are rechecked before presentation.
- Disconnect cleanup routes release through the patient owner rather than writing holder/flow state from the server.
- The owner reconciliation honors the initial claim grace, then uses the existing stale-state debounce to remove expired claims and restore the normal flow multiplier.

The original bag/rope/pose/log/observer presentation was moved intact into hangBagActivate, aside from a prefix guard and normalizing its final newline. The normal accepted-session lowering, captured-prop teardown and weapon restoration remain the original implementation. The arbitration helper adds no alive-patient restriction; dead-patient interaction eligibility is not removed by this change.

This closes the reproduced simultaneous-acquisition interleaving in the controlled execution tests. It is not a claim of live dedicated-server network testing.

## Verification results

Both local execution and the independent complete GitHub checkout passed:

| Check | Result |
| --- | --- |
| Focused preservation/consciousness/seizure/BVM/configuration/lifecycle suite | 184 passed, zero failures/errors/skips |
| Related head-tilt and Hang Bag checks | 10 passed, zero failures/errors/skips; 48 unrelated tests deselected |
| New F01-F04 executable regression cases | 28, included in the 184 |
| Full-project HEMTT check | Exit code 0; 1,632 SQF files compiled |
| Git diff whitespace check | Passed |
| Complete repository tree | Exact match to the reviewed candidate hash |

Toolchain: HEMTT 1.22.0; SQF-VM v2026.04.03-ed9f5f5. Release downloads were verified by SHA-256 before execution.

The 68 preservation snapshot cases continue to run. The original hashes remain in the test as audit provenance. Six specifically reviewed hashes were updated for the files necessarily changed by F01-F04; the other protected snapshots remain byte-identical. New behavior tests cover the revised contracts. No historical failures were broadly suppressed, marked expected-failure or removed to obtain this focused result.

HEMTT's seven existing non-blocking style suggestions were left unchanged. An initial isolated CI attempt stopped on an extra blank line at EOF in the newly extracted presentation helper. That formatting issue was corrected before the successful run; the failed attempt published no production commit and did not change main.

## Remaining limits and backlog

No Arma client or dedicated server was run here. SQF-VM executes the relevant source while mocks represent engine UI, inventory, rendering and network boundaries. Real rendered animation, live transport ordering, equipment recovery across actual reconnects and server/client integration still require in-game validation.

The previously reported 262 unresolved historical source-contract outcomes have not been cleared by this change. Nor is this a claim that all seven historical collection failures and five setup failures have been repaired. Their earlier ledger remains outstanding. The verified obsolete-locator/old-version failures must not be used as a reason to revert current behavior.

Before release, exercise a rejected surgical start followed by a retry; switch player units during a manual head hold; close auscultation during a chest flip; and have two providers request the same Hang Bag hold on a dedicated server. Include cancellation before acknowledgement, provider disconnect, dead-patient equipment recovery, and a new hold while the previous bag is lowering. Retest the existing NV/infusion and hosted-server BVM sequences as part of normal release validation.

Do not apply the superseded local consciousness/seizure patch scripts over this source. Retain the old stash as a backup until the in-game checks are complete.
