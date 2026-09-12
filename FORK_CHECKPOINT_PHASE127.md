# ACM Extended Fork Checkpoint — Phase 127

Phase 127 is a runtime-regression repair batch built directly on the Phase 120 fork. It does not reopen the completed ownership architecture. The batch addresses reported Narc Box layout/performance, Get Up recovery, ET-tube persistence/removal, direct-pressure coexistence, chest-view initialization/rolling, ventilator assessment, rocuronium paralysis, and sedation-debug inconsistencies.

## Phase 121 — Narc Box / transfusion preparation layout and carousel cost

The syringe-source and medication columns in the shared draw/preparation dialog now use wider mirrored geometry instead of inheriting ACM's narrow stock medication-list width. The visible Medication / Contents / Vials row group is built from the widened backing geometry, so medication names and stock columns no longer have to collapse into the previous horizontal footprint in ordinary Narc Box or infusion/transfusion preparation entry paths.

The syringe carousel no longer performs multi-control interpolation for A/D selection, expansion, collapse, or repaint. Selection still follows the same persistent stored-syringe semantics, but layout and carousel commits are immediate. The previous animated path could commit dozens of controls over roughly 220 ms per move and produced client-side frame hitches on some systems.

## Phase 122 — Get Up recovery when obtundation is disabled

`ACM_core_fnc_getUp` now executes on the casualty locality. Remote provider requests are routed to the patient owner before changing the lying state or animation.

The lying-state flag is no longer cleared before release eligibility is accepted. A casualty that legitimately has `ACM_core_Lying_State` can therefore use the normal release animation regardless of whether Extended obtundation is enabled. This corrects the failure where the Get Up action disappeared first, the animation gate then rejected the release, and the casualty remained locked on the floor until an external unconsciousness toggle reset the state.

## Phase 123 — ET-tube reopen, cuff workflow and extubation prerequisites

A secured ET tube is now restored as secured regardless of its stored depth value. Reopening Airway View reconstructs the tube frame, persisted depth and patient-space tip position instead of repainting the tube at a default control rectangle.

Removing the collar no longer implies that the tube has teleported out of the airway. If the cuff remains inflated, the screen stays in the cuff-management state. After a successful cuff deflation, the UI immediately transitions into the adjustable/withdrawable tube state; closing and reopening the airway view is no longer required to regain control of the tube.

The general Extubate treatment action now requires all three conditions:

1. an ET tube is inserted,
2. the securing collar is removed, and
3. the cuff is deflated.

The callback repeats the same guards, so a stale menu action cannot bypass them.

## Phase 124 — Direct-pressure lifecycle and treatment coexistence

Direct pressure no longer owns ACM's global continuous-action lock. This removes the failure where starting pressure hid or blocked unrelated medical interventions, including the provider's own release path.

A dedicated **Stop Direct Pressure** medical action is available while the provider is holding pressure on that casualty. Direct-pressure pose maintenance yields to active ACE treatments instead of repeatedly overwriting another intervention's provider animation. Torso pressure pauses its therapeutic timer while another finite/continuous treatment owns the provider, then resumes afterwards; head/limb pressure remains the freer one-handed hold.

Teardown is now idempotent and provider-explicit rather than hard-coded to `ACE_player`. Distance break, death, stale PFHs, partial starts and explicit menu stops all remove local handlers and provider/patient markers even if `ACME_DP_Active` has already become false. This prevents a stale previous hold from making later direct pressure unavailable.

The older Phase 50 regression contract was updated deliberately: ACM's global continuous-action owner remains required for systems that need exclusivity, while direct pressure is explicitly forbidden from taking or clearing that lock.

## Phase 125 — first-pass chest holes and reliable roll endpoint

On a listen/local server, Chest Seal View now generates/refreshes authoritative chest-hole state before the first local UI snapshot is read. This prevents the first pass from rendering an empty chest while waiting for the server-event join path to catch up. Remote clients continue to use the authoritative session/snapshot path.

A duplicate `MouseButtonUp` handler was also removed.

Patient rolling now holds the requested final front/back endpoint for any grounded casualty that entered the roll transaction, not only patients who were unconscious or obtunded at the beginning. The endpoint rechecks that the casualty is still grounded and out of a vehicle before applying the hold animation, reducing awake/prone snap-back failures.

## Phase 126 — ventilator assessment and rocuronium paralysis threshold

`Check Breathing` now detects when the ventilator is actively driving the patient and reports the ventilator's actual effective respiratory rate and exhaled tidal volume. It no longer labels a mechanically ventilated casualty as spontaneously bradypneic or shallow solely from the underlying neural/paralytic respiratory state while the vent is delivering breaths.

The rocuronium CBA setting had a real model mismatch: runtime physiology/debug code used a default block threshold of `0.5`, but the CBA slider initialized every mission at `3`, silently overriding the runtime default. The setting now uses the same `0.5` default and a range that permits it. The native medication-count onset envelope and existing paralysis worker are otherwise unchanged.

## Phase 127 — sedation debug consistency

The ketamine physiology worker was already using the correct shared induction-normalized sedation model: a shared sedation load of `1.0` is the configured induction threshold.

The debug menu was wrong. It read the already-normalized ketamine component, then compared it to the raw legacy ketamine threshold a second time. A displayed ketamine load such as `4.07` could therefore be physiologically well above induction while the debug panel still said `below induction`.

The debug menu now derives its induction label from the same shared normalized sedation total as the actual sedation worker (`>= 1.0`) and labels the ketamine component as an induction multiple (`xN induction`) so its units are explicit. No ketamine pharmacologic threshold or decay formula was changed in this phase.

## Validation

All fork phase tests pass after the behavioral contract updates:

- Phases 1-40: **35/35**
- Phases 41-80: **40/40**
- Phases 81-110: **30/30**
- Phases 111-127: **17/17**
- Total: **122/122 fork regression scripts**

Whole-tree structural screening also passes:

- **1,495 SQF files**
- **13 `config.cpp` files**
- comment/string-aware delimiter scan: PASS

The Phase 120 compatibility/build gates remain intact, including supplied ACE override/function/dependency closure and upstream ACM PREP/class/localization/PBO/CfgPatches preservation.

## Runtime acceptance still required

This is a source/static regression candidate, not a claim that Arma runtime behavior has been observed in this execution environment. The highest-value retest matrix is:

1. Narc Box and infusion/transfusion prep at multiple UI scales/aspect ratios; verify both columns and carousel input/performance.
2. Obtundation disabled: wake a casualty, select Get Up both on self and from another provider, verify release without Zeus intervention.
3. ET intubation: secure/cuff, reopen, remove collar, deflate cuff, adjust/withdraw in the same view, close/reopen at each stage, and confirm Extubate stays unavailable until collar-off + cuff-down.
4. Direct pressure on torso and extremities while opening the medical menu and performing another intervention; stop from menu, distance break, then apply pressure again on the same and a different limb.
5. Chest Seal View first open on a fresh local casualty and repeated front/back flips while awake, unconscious and obtunded.
6. Ketamine + rocuronium + ventilator: confirm paralysis occurs at the intended modeled load, ventilator assessment reports mechanical RR/VTe, spontaneous RR remains suppressed while paralyzed after disconnect, and debug sedation wording matches actual drug state.
7. Repeat the above on a dedicated server with two providers to exercise locality and synchronization.
