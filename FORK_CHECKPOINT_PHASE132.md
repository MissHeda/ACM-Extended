# ACM Extended Fork Checkpoint — Phase 132

Phase 132 is a reported-runtime regression batch built directly on the Phase 127 fork. It preserves the completed fork ownership architecture and public `v1.1.0` identity while correcting direct-pressure range behavior, vehicle pulse checks, Hang Bag presentation/cancellation, Plasma-Lyte inventory visibility, ultrawide UI geometry and HPMK transport physics.

## Phase 128 — direct-pressure leash and vehicle-safe pulse checks

The explicit **Stop Direct Pressure** action remains available. Direct pressure now also follows the same practical leash contract as ACM's AED: provider and patient must remain in the same vehicle context and inside the pressure radius. Walking away, entering/leaving a vehicle relative to the patient, provider incapacitation or patient loss releases pressure automatically through the normal teardown path, so a later pressure hold can start cleanly.

Pulse palpation no longer closes the medical display and tries to force the kneeling pulse minigame when both provider and patient are seated in the same vehicle. In that case the authoritative pulse check executes directly and leaves the medical UI usable. Different vehicle contexts are rejected as out of reach instead of logging a successful palpation.

## Phase 129 — Hang Bag visual/animation lifecycle

The held IV bag is now a client-local, non-physical simple object using the configured ACE IV-bag model and fluid texture. Hidden rope endpoints are local helper objects, and the gameplay IV line uses Arma's model-free engine rope rather than the custom `iv_line_segment.p3d` rope class. This removes a build-dependent reason for the hand bag/line to fail to render.

The Hang Bag watchdog no longer writes `setPosASL`, `setDir`, world velocity or model-space velocity every tick. The input lock already prevents locomotion, so those transform corrections were redundant and could create the reported slow lateral slide. The PFH cadence is reduced from 100 Hz to 20 Hz.

The watchdog also no longer repeatedly reasserts the full-body hold animation. If another system genuinely destroys the hold state after the entry grace period, Hang Bag lowers cleanly instead of fighting the animation graph, which removes the repeated jump/footstep-sound path.

On RMB/Escape cancel, the held-animation generation is retired **before** the authored lower-bag animation starts and `ACME_hang_Active` is cleared immediately. Delayed prop cleanup and weapon restoration still occur after the exit animation, but an older held loop can no longer reassert the standing pose and strand the provider.

## Phase 130 — Plasma-Lyte registry and selected-inventory visibility

All four Plasma-Lyte bags remain paired with their fluid definitions at startup:

- 1000 mL → `PlasmaLyteIV_1000`
- 500 mL → `PlasmaLyteIV_500`
- 250 mL → `PlasmaLyteIV_250`
- 100 mL → `PlasmaLyteIV_100`

The registry repair now corrects an existing item whose parallel data entry is missing/misaligned instead of only appending completely absent items. The transfusion inventory builder also reconciles Extended fluid pairs at the point of use, so another compatibility addon rebuilding ACM's fluid arrays after postInit cannot silently remove Plasma-Lyte.

A separate native menu defect was corrected: the early "does this inventory contain any supported fluid" gate previously always inspected `ACE_player`, even when the selected inventory was **Patient** or **Vehicle**. It now inspects the selected target inventory. A patient/vehicle carrying Plasma-Lyte therefore no longer depends on the provider personally carrying another transfusable bag before its list can populate.

The existing `PlasmaLyte` volume-change/physiology branch remains intact.

## Phase 131 — resolution-independent ACM/Extended UI canvas through 32:9

A shared centered design canvas now caps authored central medical UI width at 16:9 using height-derived geometry. At 16:9 the authored width is unchanged; 21:9 and 32:9 gain side gutters rather than horizontally stretching controls; narrower screens fall back to their available width.

The canvas is applied to the major native ACM and Extended interfaces that were authored from raw `safeZoneW`, including:

- ACM common pixel-grid dialogs;
- LifePak/AED monitor and Extended SYNC overlays;
- Surgical Airway inventory geometry;
- Syringe Draw / Narc Box backing dialog;
- Transfusion Menu;
- Extended Narc Box/body-map/carousel/tag/list controls;
- Extended transfusion-control overlays;
- debug panels, ventilator technician prompt and Megacode auxiliary dialogs;
- EMMA horizontal anchor while retaining its pixel-square device art.

The LifePak 1.05 background scale is now centered correctly instead of multiplying the absolute safe-zone origin. Runtime SYNC button/LED and QRS flags use the same base/background mapping as the native monitor, so the Extended overlay remains aligned on ultrawide.

The audit also found native Transfusion Menu axis defects independent of aspect scaling: one arm X coordinate was derived from `safeZoneY`, and four leg Y coordinates were derived from `safeZoneX/safeZoneW`. Those controls now use the correct axis and the same bounded canvas as the body art.

Full-screen procedural surfaces (laryngoscopy, IV placement, chest-seal and thoracostomy workspaces) intentionally retain the actual full safe zone because their cursor/image coordinate systems are screen surfaces rather than centered panel layouts.

## Phase 132 — HPMK "magic carpet" transform isolation

A wrapped HPMK no longer has **any `attachTo` relationship** with the casualty. Its visible blanket is a local simple object with no simulation, collision or network ownership; a lightweight local follower mirrors the casualty's visual world position and orientation at 20 Hz.

Dropped blankets likewise render from the geometry-free network interaction anchor without attaching the local visual to it. The server-side HPMK worker still destroys any legacy networked blanket child discovered on a wrapped casualty.

This removes the final parent/child transform chain between HPMK presentation and the patient, so ACE drag, carry, recovery-position, ragdoll and placement systems cannot be opposed by a blanket attachment and accelerate the patient/provider into the recurrent floating "magic carpet" failure.

## Validation

All canonical fork phase regressions pass after the contract changes:

- Phases 1-30: PASS
- Phases 31-60: PASS
- Phases 61-90: PASS
- Phases 91-115: PASS
- Phases 116-132: PASS
- **Total: 127/127 fork phase regression scripts**

Whole-tree structural screening passes:

- **1,496 SQF files**
- **13 `config.cpp` files**
- comment/string-aware delimiter scan: PASS

The Phase 120 ACM/ACE compatibility/build gates and Phase 121-127 runtime-regression contracts remain intact. Public version remains **v1.1.0**.

## Runtime acceptance matrix

This remains a source/static candidate until tested in Arma. Highest-value retests are:

1. Direct pressure: start on each body region, use manual Stop, walk outside the leash, enter/exit a vehicle relative to the patient, then immediately reapply pressure.
2. Vehicle pulse: two occupants in the same vehicle, self/patient inventory interactions open, palpate multiple sites without the medical window closing; verify different vehicles reject the attempt.
3. Hang Bag: verify bag model + IV line on 250/500/1000 mL blood/plasma/crystalloid, no lateral drift or repeated jump sound, RMB/Escape exit returns movable crouch and restores weapon, auto-lower still works when the bag empties.
4. Plasma-Lyte: test 100/250/500/1000 mL from medic, patient and vehicle inventories, hang/adjust/pressure-infuse and verify volume admission.
5. UI: 16:9, 21:9 and 32:9 at multiple Arma UI-size settings; specifically Narc Box, Syringe Draw, Transfusion Menu, LifePak/AED + SYNC, Surgical Airway, Stethoscope/BP and Extended overlays.
6. HPMK: wrapped patient through drag, carry, set-down, recovery position, roll/flip, head elevation and repeated combinations with two providers; verify no floating/velocity launch and blanket follows visually.
7. Repeat 1-6 on dedicated server with two clients to exercise locality and visual ownership.
