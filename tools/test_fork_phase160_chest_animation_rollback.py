#!/usr/bin/env python3
"""RC20 guard: corrected chest choreography must not resurrect the failed rc11-14 ownership model."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
acquire = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
provider = read("addons/acm_extended/functions/fn_chestAccessVestProvider.sqf")
use_steth = read("addons/breathing/functions/fnc_useStethoscope.sqf")
begin_steth = read("addons/acm_extended/functions/fn_beginStethoscopeAction.sqf")
config = read("addons/acm_extended/config.cpp")

# Corrected animation prep exists, but it wraps the clinical action and launches native treatment exactly once.
start = treatment.index("// Chest-access preparation is a physical gear transaction")
end = treatment.index("// Auscultation owns its own modal display", start)
block = treatment[start:end]
assert "ACME_chestAccessPreflightActive" in block
assert "ACME_chestAccess_readyLease" in block
assert "ACM_core_fnc_treatmentNative" in block
assert "ace_medical_treatment_fnc_treatment;" not in block
assert "ContinuousAction_" not in block

# Patient animation readiness is casualty-side; provider presentation has a bounded fail-open handshake.
assert '"ACME_HeadElevPatientGrab"' in acquire
assert "ACME_chestAccessProviderReady" in acquire
assert "ACME_chestAccessProviderReady" in provider
assert "4.75" in acquire

# The fixed auscultation lifecycle remains independent from chest preparation.
assert "_entryEpoch" not in use_steth
assert "ACME_fnc_beginStethoscopeAction" in use_steth
assert 'ACM_core_ContinuousAction_Session", [_patient, _epoch]' in begin_steth
assert begin_steth.index("_args call _onStart;") < begin_steth.index('call ACME_fnc_treatmentPoseStart;')

# Workspace pose may exist again, but it is presentation-only and cannot gate the panel.
assert "class ACME_ChestSealWorkspace:" in config

print("PASS rc20: corrected chest choreography excludes failed rc11-14 ownership model")
