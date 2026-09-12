# ACM Extended Fork Checkpoint — Phase 25

Local fork branch: `dev/acm-fork`

Current preserved source commit: `88f03cc2b54a11bd421e53bd0ba918c3399b1bef`

## Completed since the previous GitHub checkpoint

- Phase 20: split circulation, consciousness, IV procedure, positioning, Megacode and drug-physiology startup configuration.
- Phase 21: split resuscitation and TBI progression configuration.
- Phase 22: split device, menu, airway, flight, perfusion, ventilator and Narc Box configuration domains.
- Phase 23: moved TBI, blast-lung, circulation, ventilator audio/alarm and NRB runtime registrations behind explicit subsystem entry points.
- Phase 24: split Hang Bag, HPMK thermal/visual, ACRE babble and procedure-environment runtime ownership.
- Phase 25: split chest-seal collaboration, HPMK transport cleanup, hypothermia runtime, base medical-body overlays and blood fridge/cooler cold-chain runtime ownership.

The global `ACME_fnc_postInit` is now approximately 1,759 lines, down from more than 4,000 before the initialization/runtime ownership split.

The fork still has zero runtime ACM/ACE/ACME function-pointer monkey patches. All fork regression tests through Phase 25 and the SQF/config delimiter audit pass at this checkpoint.

## Preserved artifacts

Source ZIP SHA-256: `6ec46d328111e810ece6498405fcdb5ad0576bf691806496682dd48a5a7ab2d8`

Full Git bundle SHA-256: `346ca791a1064a9731b68fa11ba4c0cbe38b851ff5a0f5ad5303a1c1352ddd60`

The Git bundle verifies as complete and contains the full `dev/acm-fork` history through Phase 25.

## Validation boundary

These phases are source-ownership/refactor work. The regression suite and structural checks do not substitute for an Arma 3 engine/PBO/multiplayer run. In-game acceptance remains required before treating the fork as release-ready.
