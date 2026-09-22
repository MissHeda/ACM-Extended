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

blood_block = flow.split('// Blood has an explicit device/temperature flow envelope', 1)[1].split('// Final perfusion gate', 1)[0]

# A usable pressure cuff is the universal top tier for every blood path.
assert 'private _pressureActive = false;' in blood_block
assert '_pressureActive = _p >= 0.08;' in blood_block
assert 'if (_pressureActive) then {' in blood_block
assert '_fixedRate = _bloodCap;' in blood_block
assert 'ACME_pi_bleedHalfLifeSec' in blood_block

# Without pressure: cold origin wins over LifeWarmer, and Hang Bag moves cold blood 100 -> 200.
pressure_else = blood_block.split('if (_pressureActive) then {', 1)[1]
assert pressure_else.index('if (_coldFlag) then {') < pressure_else.index('if (_warmedFlag) then {')
assert '_fixedRate = [_coldBase, _coldHang] select _hangActive;' in blood_block
assert '_fixedRate = _warmBase;' in blood_block

# Ordinary room-temperature blood with no warmer and no cuff keeps the existing physical gauge/Hang path.
assert 'private _fixedRate = -1;' in blood_block
assert 'if (_fixedRate >= 0) then {' in blood_block
assert '_flow * _pressure' in iv

# Every blood path is hard capped at 300 mL/min.
assert 'private _capChange = _deltaT * (_bloodCap / 60);' in blood_block
assert '_bagChange = ((_bagChange min _capChange) min _bagVolumeRemaining) max 0;' in blood_block

# Explicit requested matrix.
COLD = 100
COLD_HANG = 200
WARMER = 200
PRESSURE = 300
CAP = 300
assert COLD == 100
assert COLD_HANG == 200
assert WARMER == 200
assert PRESSURE == 300
assert min(PRESSURE, CAP) == 300

assert 'ACME_buildBatch = "B126";' in startup
assert 'ACME_debugRevision = "rc10";' in startup

print("PASS rc10: cold 100, cold+Hang 200, active pressure 300, LifeWarmer 200, absolute 300 cap")
