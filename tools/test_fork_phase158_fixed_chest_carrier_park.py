#!/usr/bin/env python3
"""RC13 regression: removed chest carriers park once in world space and never follow patient motion."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
access = read("addons/acm_extended/functions/fn_chestAccessVestPark.sqf")
seal = read("addons/acm_extended/functions/fn_chestSealParkCarrier.sqf")
acquire = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
runtime = read("addons/acm_extended/functions/fn_initChestSealProcedureRuntime.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

preflight = treatment.split("// Chest-access preflight.", 1)[1].split("// BVM uses ACM", 1)[0]
assert 'private _providerReady' not in preflight
assert '(_ready isEqualType 0) && {_ready >= 0} && {serverTime >= _ready}' in preflight
assert '], 12, {' in preflight

for park in (access, seal):
    assert 'ACME_chestFixedPark' in park
    assert 'private _needsInitialPark' in park
    assert 'if (!_needsInitialPark) exitWith {' in park
    # Head geometry exists only in first-placement path, after the early fixed-state exit.
    assert park.index('if (!_needsInitialPark) exitWith {') < park.index('modelToWorldVisual')
    assert 'ACME_chestAccessCarrierGap", 0.85' in park

assert '_prop setVariable ["ACME_chestFixedPark", nil, false];' in acquire
assert '_headProp setVariable ["ACME_chestFixedPark", nil, false];' in acquire
assert '_prop setPosATL (getPosATL _p);' in acquire
assert 'ACME_chestAccessCarrierGap = 0.85;' in runtime

assert 'ACME_buildBatch = "B130";' in startup
assert 'ACME_debugRevision = "rc14";' in startup

print("PASS rc14: chest actions launch on patient readiness and carrier park target is fixed")
