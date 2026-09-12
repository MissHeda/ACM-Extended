# ACM Extended Fork Checkpoint — Phase 136

Phase 136 continues the Phase 132 runtime-regression baseline, with the Phase 133 rope correction requested after in-game validation. Public/runtime version remains **v1.1.0**.

## Phase 133 — restore the validated custom Hang Bag IV line

Phase 132 changed the Hang Bag line to Arma's model-free engine rope. That specific change is reverted. Hang Bag again uses the bundled custom IV rope classes:

- `ACME_IVLine_Rope` for clear/crystalloid/medication lines
- `ACME_IVLine_Rope_Blood` for blood
- `ACME_IVLine_Rope_Plasma` for plasma

The class decision is local to each Hang Bag session so simultaneous providers cannot overwrite one another's rope style. The rest of the Phase 132 Hang Bag repair is preserved: the hand bag remains a local non-physical visual, rope helpers remain local, the tick remains 20 Hz, there are no provider `setPosASL`/`setDir`/velocity correction writes, the hold pose is not repeatedly restarted, and cancel still retires the held-animation generation before the authored exit.

## Phase 134 — named remote-command endpoints

Raw remote execution of `say3D`, `forceWalk` and `deleteVehicle` has been removed from active fork SQF. These commands can be blocked by strict mission `CfgRemoteExec` command policy even when mod functions are imported normally. They now terminate in named fork functions:

- `ACME_fnc_remoteSay3D`
- `ACME_fnc_remoteDeleteVehicle`
- `ACME_fnc_forceWalkLocal`
- `ACM_airway_fnc_remoteSay3D` for the native airway-owned suction path

The airway wrapper remains in `addons/airway`; no reverse dependency from native airway into `acm_extended` was introduced.

## Phase 135 — fork-owned CfgRemoteExec closure

Every fork-owned function that appears as a `remoteExec`/`remoteExecCall` target is now represented by a named `CfgRemoteExec > Functions` entry. The fork does **not** set `Functions.mode` or `Commands.mode`, so it does not seize mission-wide remote-execution policy.

Current closure covers **22 fork-owned remote targets**. Server-only endpoints are constrained with `allowedTargets = 2`, including blood-fridge spawn/cold-chain nudges, Megacode cable server work and network-helper deletion. The cooler scale replay remains the explicit JIP-capable function.

## Phase 136 — remote target registration integrity

The remote-execution whitelist is now checked bidirectionally against real registered functions. ACME entries must resolve to a registered Extended function file; the native airway sound endpoint must remain PREPed by `addons/airway`. This prevents stale whitelist entries and prevents new fork-owned remote dispatches from being added without a matching named policy entry.

## Validation

- Phases 1-40: **35/35**
- Phases 41-80: **40/40**
- Phases 81-110: **30/30**
- Phases 111-136: **26/26**
- Total: **131/131 fork phase regression scripts passing**
- Structural screening: **1,500 SQF files**, **13 `config.cpp` files**, PASS

This is still source/static validation. The restored custom rope and the new remote-execution policy need normal Arma multiplayer acceptance on hosted and dedicated sessions, particularly with a mission that uses a strict imported `CfgRemoteExec` whitelist.
