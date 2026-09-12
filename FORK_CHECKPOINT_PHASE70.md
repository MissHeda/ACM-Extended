# ACM Extended Fork Checkpoint — Phase 70

Branch target: `dev/acm-fork`

This checkpoint extends the authoritative-writer work through persistent physiology, transfusion thermal state, core temperature and shared evacuation disposition.

## New work since Phase 67

- Phase 68: centralized patient blood thermal flags/clocks behind `ACME_fnc_bloodThermalStateCommit` without changing the existing per-patient thermal model.
- Phase 69: centralized `ACME_hypo_temp` behind `ACME_fnc_hypothermiaTemperatureCommit` across cooling, passive/HPMK rewarming, manual staging, restore and reset.
- Phase 70: centralized `ACME_requiresEvac` behind `ACME_fnc_evacuationRequirementCommit` while deliberately retaining the existing shared-boolean semantics.

## Validation

- 30/30 fork phase tests through Phase 35 pass.
- 35/35 fork phase tests for Phases 36-70 pass.
- Total: 65/65 fork phase regression tests pass.
- Balanced delimiter scan: 1,474 SQF files + 13 config.cpp files pass.
- HEMTT is not installed in the current environment.

This remains source/static validation and is not a substitute for Arma config merge, PBO compile/signing, dedicated-server or multiplayer acceptance testing.
