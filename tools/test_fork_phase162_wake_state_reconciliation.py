#!/usr/bin/env python3
"""RC17 guard: wake interventions repair ACE medical/state-machine desynchronization."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

post = read("addons/core/XEH_postInit.sqf")
blast = read("addons/acm_extended/functions/fn_blastApply.sqf")
roc = read("addons/acm_extended/functions/fn_rocuroniumTick.sqf")
obt = read("addons/acm_extended/functions/fn_obtundedApply.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

# Every ace_medical_WakeUp event gets a next-frame coherence check after native ACE has first chance.
assert '[QACEGVAR(medical,WakeUp), {' in post
wake = post.split('[QACEGVAR(medical,WakeUp), {', 1)[1].split('[QGVAR(playWakeUpSound), {', 1)[0]
assert 'CBA_fnc_execNextFrame' in wake
assert 'ACEFUNC(medical_status,hasStableVitals)' in wake
assert 'FUNC(isForcedUnconscious)' in wake
assert 'CBA_statemachine_fnc_getCurrentState' in wake
assert 'CBA_statemachine_fnc_manualTransition' in wake
assert '"Unconscious", "Injured"' in wake
assert 'ACEFUNC(medical_status,setUnconsciousState)' in wake
assert 'ACME_obtunded_wakeStimGraceUntil' in wake

# Normal gameplay systems must use ACE's public state-machine setter for new KO/wake requests.
assert 'call ace_medical_fnc_setUnconscious;' in blast
assert 'ace_medical_status_fnc_setUnconsciousState' not in blast
assert 'call ace_medical_fnc_setUnconscious;' in roc
assert 'call ace_medical_status_fnc_setUnconsciousState;' not in roc

# Intentional KO -> obtunded conversion manually transitions the state machine instead of only flipping the flag.
assert 'CBA_statemachine_fnc_manualTransition' in obt
assert '"ACMEObtundedWake"' in obt

assert 'ACME_buildBatch = "B133";' in startup
assert 'ACME_debugRevision = "rc17";' in startup

print("PASS rc17: wake events self-heal state-machine desync and new KO paths stay synchronized")
