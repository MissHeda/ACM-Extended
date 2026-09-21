#!/usr/bin/env python3
"""RC15 guard: failed animated chest-access preflight/workspace experiment remains removed."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
acquire = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
runtime = read("addons/acm_extended/functions/fn_registerChestAccessVestRuntime.sqf")
use_steth = read("addons/breathing/functions/fnc_useStethoscope.sqf")
config = read("addons/acm_extended/config.cpp")
owner = read("addons/acm_extended/functions/fn_ownerDispatch.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

# No asynchronous carrier-preflight gate in the treatment bridge.
assert "// Chest-access preflight." not in treatment
assert "ACME_chestAccessPreflightActive" not in treatment
assert "ACME_chestAccessPreflightToken" not in treatment

# Carrier custody is back to the simple pre-animation implementation.
assert 'params [["_patient", objNull, [objNull]]];' in acquire
assert "ACME_HeadElevPatientGrab" not in acquire
assert "chestAccessVestProvider" not in acquire

# Treatment events own simple removal/restoration as they did before the experiment.
assert "ace_treatmentStarted" in runtime
assert "ACME_fnc_chestAccessVestEvent" in runtime

# Auscultation uses its pre-experiment lifecycle, with no reserved-entry epoch machinery.
assert "_entryEpoch" not in use_steth
assert "ACME_fnc_beginStethoscopeAction" in use_steth

# Experiment-only move state/functions/routes are gone.
assert "class ACME_ChestSealWorkspace:" not in config
assert "class chestAccessVestProvider {};" not in config
assert "class chestSealProviderHoldStart {};" not in config
assert 'case "chestAccessVestProvider"' not in owner
assert 'case "chestSealProviderHold"' not in owner

assert 'ACME_buildBatch = "B131";' in startup
assert 'ACME_debugRevision = "rc15";' in startup

print("PASS rc15: chest-access animation experiment rolled back to pre-animation architecture")
