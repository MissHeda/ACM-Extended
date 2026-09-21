#!/usr/bin/env python3
"""RC9 regression: carrier removal must end supine, release its animation lease, and gate chest UI startup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "addons" / "acm_extended" / "functions"

def read(path):
    return path.read_text(encoding="utf-8", errors="replace")

cfg = read(ROOT / "addons" / "acm_extended" / "config.cpp")
vest = read(FUN / "fn_chestAccessVestAcquire.sqf")
patient_begin = read(FUN / "fn_chestSealPatientBegin.sqf")
seal_open = read(FUN / "fn_chestSealOpen.sqf")
startup = read(FUN / "fn_initForkStartupRuntime.sqf")

# The shared Grab/Release theatre must finish in ACM's authored supine state, not BI's prone injured idle.
release = cfg.split("class ACME_HeadElevPatientRelease:", 1)[1].split("};", 1)[0]
assert 'ConnectTo[] = {"ACM_LyingState", 0.1};' in release
assert 'ConnectTo[] = {"AinjPpneMstpSnonWnonDnon", 0.1};' not in release

# Carrier removal owns its exact patient animation lease only until the release motion has ended.
assert '(_lock param [0,""]) == _token' in vest
assert '(_lock param [1,""]) == "chest-access-vest"' in vest
assert '_p setVariable ["ACME_patientAnimLock", [], true];' in vest

# Final fallback is explicitly face-up and is published before the treatment/minigame is allowed to continue.
assert '["ace_common_switchMove", [_p, _faceUp]] call CBA_fnc_globalEvent;' in vest
assert '_p setVariable ["ACME_CS_facing", "front", true];' in vest
assert '_p setVariable [_readyVar, serverTime + 0.10, true];' in vest

# Chest-seal must not make a stale roll decision from the pose that existed before carrier removal.
assert 'private _vestOwnsSupine = _hadVest' in patient_begin
assert 'if (_canNormalize && {!_vestOwnsSupine} && {_actualNow != "front"}) then {' in patient_begin

# A preparation timeout aborts instead of force-opening over unfinished patient/provider animation.
assert 'private _abortPrepare = {' in seal_open
assert '], 12, _abortPrepare] call CBA_fnc_waitUntilAndExecute;' in seal_open
assert '4, _open] call CBA_fnc_waitUntilAndExecute;' not in seal_open

assert 'ACME_buildBatch = "B125";' in startup
assert 'ACME_debugRevision = "rc9";' in startup

print("PASS rc9: supine carrier release + lease retirement + preparation-gated chest UI")
