# ACM Extended Fork Checkpoint — Phase 78

Branch target: `dev/acm-fork`

This checkpoint continues the source-level fork ownership migration through Phase 78. It is a full-source snapshot, not an incremental patch.

## New ownership boundaries since Phase 70

- Phase 71: native rhythm high-HR floor and shock/ROSC grace clocks.
- Phase 72: ventilator-derived pulmonary shunt.
- Phase 73: rocuronium awake-paralysis sympathetic stress state.
- Phase 74: latched awake-paralysis awareness outcome.
- Phase 75: derived awake-paralysis flag.
- Phase 76: rocuronium respiratory-muscle apnea.
- Phase 77: blast-lung episode exposure/onset/last-injury metadata.
- Phase 78: medication-toxicity per-family generation latch.

These phases preserve the existing physiology, thresholds and treatment behavior. The work changes mutation ownership and persistence routing only. Existing direct versus `ACME_fnc_setVarNet` publication contracts were retained where the live code depended on them.

## Validation

- Fork regression tests through Phase 35: 30/30 pass.
- Fork regression tests Phases 36-78: 43/43 pass.
- Total: 73/73 pass.
- Structural delimiter scan: 1,483 SQF and 13 config.cpp files pass.
- New CfgFunctions registrations resolve to their Phase 71-78 source files.
- HEMTT is not installed in this environment.

This is source/static validation only. Arma config merge, PBO compilation/signing and multiplayer regression remain required before release use.
