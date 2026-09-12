# ACM Extended Fork Checkpoint — Phase 85

This checkpoint extends the Phase 78 source with authoritative writer boundaries for durable ventilator, provider-inventory, head-elevation, IV/EJ and thoracostomy state.

## Completed in Phases 79-85

- Phase 79: `ACME_vent_connected` now crosses `ACME_fnc_ventConnectionCommit`, including connect/stop, extubation, battery shutdown, hard stop, custody, preset-mode and reset paths. Historical direct versus deduplicated publication behavior is preserved.
- Phase 80: `ACME_vent_powerOn` now crosses `ACME_fnc_ventPowerCommit` from power-switch, hard-stop, custody/return and patient-clear paths.
- Phase 81: virtual blood-cooler contents now cross `ACME_fnc_coolerStoreCommit`; published HashMap snapshots and per-cooler arrays are copied to prevent retained mutable aliases while keeping existing local/public publication choices.
- Phase 82: prepared-syringe/Narc Box inventory now crosses `ACME_fnc_narcStoreCommit`, including death/respawn, refund, draw, compound, inject, tag and discard paths. Published rows are copied on commit.
- Phase 83: head-elevation resume intent now has one networked writer.
- Phase 84: persistent IV/EJ marks and `ACME_IV_MarkVer` now cross `ACME_fnc_ivMarksCommit`; normal edits publish marks/version atomically while hard reset preserves the historical no-version-bump behavior.
- Phase 85: thoracostomy total output, rolling hourly rate and rolling history now cross `ACME_fnc_thoraOutputStateCommit`; server-local history versus published total/rate semantics are preserved.

## Validation

- 30/30 fork phase tests through Phase 35 pass.
- 50/50 fork phase tests for Phases 36-85 pass.
- 80/80 fork phase regression tests total.
- Structural delimiter screening passes across 1,490 SQF files and 13 `config.cpp` files.
- All Phase 79-85 CfgFunctions registrations resolve to source files.
- HEMTT is not installed in the current environment, so engine config merge, PBO build/signing and multiplayer acceptance remain pending.

Full source ZIP SHA-256: `57a0987553e0405c0ade325924c202f131c47ff4c2c4f6b6f8ebb185fd865896`

The full source ZIP is the canonical recoverable artifact. This GitHub file documents the checkpoint and does not imply that the binary-heavy 225 MB source tree was pushed through the connector.
