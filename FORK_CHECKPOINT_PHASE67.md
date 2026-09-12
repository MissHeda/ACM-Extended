# ACM Extended Fork Checkpoint — Phase 67

Branch target: `dev/acm-fork`

This checkpoint continues the fork ownership work from Phase 58 and focuses on authoritative writers for persistent physiological/intervention state plus the serialization boundary.

## Phases 59-67

- Phase 59: one persistent obtundation-state writer.
- Phase 60: one blast-lung severity writer.
- Phase 61: atomic native-rhythm hold kind/rhythm writer.
- Phase 62: invariant NRB mask/O2/delivery writer.
- Phase 63: one blast-lung ARDS latch/dwell writer.
- Phase 64: one durable ETT insertion/cuff/secure-state writer, preserving valid pre-seating cuff inflation.
- Phase 65: one rocuronium paralysis writer.
- Phase 66: one atomic cumulative calcium-credit writer.
- Phase 67: clinical restore/reset routes owner-gated persistent state back through those mutation boundaries instead of generic `setVariable` publication.

## Ownership milestone

`addons/acm_extended` still has zero direct native `ACM_*` state publications and zero direct `ace_*` state publications. Important Extended physiology/intervention state increasingly follows the same one-authoritative-writer rule.

## Validation

- Fork regression batch 1: 30/30 tests through Phase 35 pass.
- Fork regression batch 2: 32/32 tests for Phases 36-67 pass.
- Total: 62/62 fork phase regression tests pass.
- Balanced delimiter scan: 1,471 SQF files + 13 config.cpp files pass.
- HEMTT: not installed in this environment.

The single combined regression wrapper exceeds the execution window, so validation was performed in two bounded batches. This is not an engine/config/PBO or multiplayer acceptance test.
