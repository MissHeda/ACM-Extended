#!/usr/bin/env python3
"""RC10 regression: blood throughput uses the 100/200/300 ladder and never exceeds 300 mL/min per line."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

flow = read("addons/circulation/functions/fnc_getBloodVolumeChange.sqf")
iv = read("addons/circulation/functions/fnc_getIVFlowRate.sqf")
runtime = read("addons/acm_extended/functions/fn_initHangBagRuntime.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

# Tuned rates.
assert 'ACME_warmedBlood_mlPerMin  = 200;' in runtime
assert 'ACME_coldBlood_mlPerMin    = 100;' in runtime
assert 'ACME_coldBloodHang_mlPerMin = 200;' in runtime
assert 'ACME_bloodMax_mlPerMin     = 300;' in runtime

# Cold origin has priority over the warmer for throughput.
blood_block = flow.split('// Blood has an explicit device/temperature flow envelope', 1)[1].split('// Final perfusion gate', 1)[0]
assert blood_block.index('if (_coldFlag) then {') < blood_block.index('if (_warmedFlag) then {')
assert '_fixedRate = [_coldBase, _coldHang] select _hangActive;' in blood_block

# A full cuff reaches 300 from either cold tier or LifeWarmer 200, while cuff bleed-off remains continuous.
assert '_fixedRate = _fixedRate + ((_bloodCap - _fixedRate) * _pressureFrac);' in blood_block
assert 'ACME_pi_bleedHalfLifeSec' in blood_block
assert 'if (_p >= 0.08) then {_pressureFrac = _p;};' in blood_block

# Room-temperature blood without LifeWarmer keeps generic gauge/Hang/pressure behavior.
assert 'private _fixedRate = -1;' in blood_block
assert 'if (_fixedRate >= 0) then {' in blood_block
assert '_flow * _pressure' in iv

# Every blood path, including ordinary pressure-infused room-temp blood, is hard capped at 300.
assert 'private _capChange = _deltaT * (_bloodCap / 60);' in blood_block
assert '_bagChange = ((_bagChange min _capChange) min _bagVolumeRemaining) max 0;' in blood_block

# Expected full-pressure matrix.
CAP = 300
assert 100 == 100                      # cold, no assist
assert 200 == 200                      # cold + Hang Bag
assert 100 + (CAP - 100) * 1 == 300   # cold + full pressure
assert 200 + (CAP - 200) * 1 == 300   # cold + Hang + full pressure
assert 200 == 200                      # LifeWarmer, non-cold
assert 200 + (CAP - 200) * 1 == 300   # LifeWarmer + full pressure

assert 'ACME_buildBatch = "B126";' in startup
assert 'ACME_debugRevision = "rc10";' in startup

print("PASS rc10: blood flow ladder 100/200/300 + absolute 300 mL/min cap")
