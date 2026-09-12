# ACM Extended Fork Checkpoint — Phase 101

Phase 101 is the build-readiness checkpoint for the fork. The useful authoritative-writer migration is complete; remaining work should prioritize real config/PBO/Arma runtime validation instead of adding wrappers to transient UI or animation state.

## Phase 101: unified validation harness

`tools/validate_fork.py` is now the single repository-local validation entry point. It:

- discovers fork phase regression tests numerically,
- supports bounded phase ranges for constrained environments,
- performs comment/string-aware SQF/config delimiter screening,
- can run `hemtt check`, and optionally `hemtt build`, when a HEMTT executable is available,
- exits nonzero on any phase-test, structural-scan or requested HEMTT failure.

Typical source/static validation:

```text
python tools/validate_fork.py
```

Bounded validation:

```text
python tools/validate_fork.py --min-phase 71 --max-phase 101
```

HEMTT validation on a machine with HEMTT installed:

```text
python tools/validate_fork.py --hemtt --build
```

## Validation

The full fork regression stack passes in bounded runs:

- Phases 1-35: **30/30**
- Phases 36-70: **35/35**
- Phases 71-101: **31/31**
- Total: **96/96** fork phase regression scripts

The unified structural scan passes across **1,504 SQF files and 13 `config.cpp` files**.

The Phase 100 offline preprocessor/build-source gate also passes for:

- **13 addons**
- **111 repository-local preprocessor files**
- **1,032 ACME CfgFunctions registrations**

## Recovered-source provenance

The Phase 100 source snapshot was recovered from the preserved Phase 100 archive. Its local file records contained the current source/config/tests through Phase 100 but the archive's central directory/trailing binary payload was truncated. The recovered source was overlaid onto the intact Phase 78 full package.

Every recovered binary asset that could be compared against Phase 78 was checked: **2,311 binary files were byte-identical, with zero changed and zero new-only binaries**. The intact Phase 78 binary tail therefore supplies only assets for which no newer binary revision was observed in the recovered Phase 100 archive.

## Remaining validation boundary

A real HEMTT/PBO build could not be executed in this environment because HEMTT is not installed and external binary download is unavailable from the execution container. Phase 101 therefore does not claim an engine-clean build.

Before release use, the fork still requires:

1. `hemtt check`
2. `hemtt build`
3. PBO load/config-merge inspection in Arma 3
4. single-player clinical smoke tests
5. dedicated-server + headless-client validation
6. two-provider multiplayer synchronization regression
7. complete ACME feature regression against the current v1.1.0 behavior

No additional broad authoritative-writer phase is recommended unless runtime testing exposes a concrete ownership defect.
