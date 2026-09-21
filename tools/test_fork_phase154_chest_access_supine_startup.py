#!/usr/bin/env python3
"""RC8 regression: animated chest access must hand off supine and chest-seal may not open before preparation."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "addons" / "acm_extended" / "functions"

def read(path):
    return path.read_text(encoding="utf-8", errors="replace")

vest = read(FUN / "fn_chestAccessVestAcquire.sqf")
seal_open = read(FUN / "fn_chestSealOpen.sqf")
startup = read(FUN / "fn_initForkStartupRuntime.sqf")

# Generic chest access (auscultation/check breathing/inspect/CPR) exits the animated carrier lift face-up.
assert 'private _side = if (_ctx == "access") then {' in vest
assert '_p setVariable ["ACME_CS_facing", "front", true];' in vest
assert '_readyAt = serverTime + 0.20;' in vest
assert '"front"' in vest

# Chest-seal keeps its separate post-carrier normalization path; it is not collapsed into generic access.
assert '} else {\n            [_p, _p getVariable ["ACME_CS_facing","front"]] call ACME_fnc_chestSealActualSide' in vest

# A preparation timeout can never force-open the minigame over a still-running carrier/roll animation.
assert 'private _abortPrepare = {' in seal_open
assert '], 12, _abortPrepare] call CBA_fnc_waitUntilAndExecute;' in seal_open
assert '4, _open] call CBA_fnc_waitUntilAndExecute;' not in seal_open
assert 'Unable to prepare the patient for chest access.' in seal_open

assert 'ACME_buildBatch = "B124";' in startup
assert 'ACME_debugRevision = "rc8";' in startup

print("PASS rc8: supine chest-access handoff + preparation-gated chest-seal open")
