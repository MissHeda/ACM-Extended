# ACM Extended Fork Checkpoint — Phase 78

Branch target: `dev/acm-fork`

This checkpoint continues the source-level fork ownership migration through Phase 78. The recoverable canonical artifact is the complete source ZIP preserved in the ACM Extended Library; this GitHub file is the branch checkpoint record rather than a claim that the entire 225 MB source tree has been pushed through the connector.

## New ownership boundaries since Phase 70

- Phase 71: native rhythm high-HR floor and shock/ROSC grace clocks.
- Phase 72: ventilator-derived pulmonary shunt.
- Phase 73: rocuronium awake-paralysis sympathetic stress state.
- Phase 74: latched awake-paralysis awareness outcome.
- Phase 75: derived awake-paralysis flag.
- Phase 76: rocuronium respiratory-muscle apnea.
- Phase 77: blast-lung episode exposure/onset/last-injury metadata.
- Phase 78: medication-toxicity per-family generation latch.

These phases preserve the existing physiology, thresholds and treatment behavior. Existing direct versus `ACME_fnc_setVarNet` publication contracts were retained where the live code depended on them.

## Validation

- Fork regression tests through Phase 35: 30/30 pass.
- Fork regression tests Phases 36-78: 43/43 pass.
- Total: 73/73 pass.
- Structural delimiter scan: 1,483 SQF and 13 config.cpp files pass.
- Phase 71-78 CfgFunctions registrations resolve to source files.
- HEMTT is not installed in this environment.

Source ZIP: `ACM_Extended_Fork_Dev_Phase78_Source.zip`

SHA-256: `cc0c6fd783086c9dd77baa52f7aae16a362f00e19a568eda56f67916bffd0ab4`

Size: 225,103,579 bytes.

This is source/static validation only. Arma config merge, PBO compilation/signing and multiplayer regression remain required before release use.
