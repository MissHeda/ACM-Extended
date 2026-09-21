#!/usr/bin/env python3
"""RC12: restore the pre-regression chest action contract after animated carrier preparation."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
pose = read("addons/acm_extended/functions/fn_treatmentPoseStart.sqf")
roll_provider = read("addons/acm_extended/functions/fn_rollProviderStart.sqf")
runtime = read("addons/acm_extended/functions/fn_initChestSealProcedureRuntime.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

# Frozen provider work must use the exact known-good priority-1 state entry.
main = pose.split("private _fnStartMain = {", 1)[1].split("// Crouch first.", 1)[0]
assert '[_medic, _main, 1] call ACME_fnc_doAnim;' in main
assert '[1,0] select _smoothChest' not in main

# Freeze on the naturally reached frame. Do not hard-seek the owner at the hold point.
freeze = pose.split("// Freeze the owner on the frame it naturally reached.", 1)[1].split("private _jip", 1)[0]
assert '_medic setAnimSpeedCoef 0;' in freeze
assert '_medic switchMove [_main, _phase, 1, false];' not in freeze

# The outer provider token follows the actual frozen roll episode instead of lingering on a fail-safe timer.
assert 'private _poseStillOwnsRoll' in roll_provider
assert 'if (!_poseStillOwnsRoll) exitWith {' in roll_provider
assert 'ACME_rollProviderActive' in treatment

# The configured hold points remain the original values.
assert '["roll", 2.2]' in runtime
assert '["stethoscope", 0.421]' in runtime
assert '["chestSealWorkspace", ACME_CS_workspaceHoldAt]' in runtime

# Carrier-prepped auscultation reserves a new continuous-action epoch and passes it into useStethoscope.
steth = treatment.split('if (_classKey == "usestethoscope") then {', 1)[1].split('} else {\n                if (_classKey == "cpr")', 1)[0]
assert 'private _entryEpoch = (missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", 0]) + 1;' in steth
assert 'missionNamespace setVariable ["ACM_core_ContinuousAction_Active", true];' in steth
assert '[_m,_p,_bodyPart,true,_entryEpoch] call ACM_breathing_fnc_useStethoscope;' in steth
assert '[_m,_p,_bodyPart,true] call ACM_breathing_fnc_useStethoscope;' not in steth

# CPR uses its actual configured callback after revalidating canCPR, not a delayed generic treatment launcher.
cpr = treatment.split('if (_classKey == "cpr") then {', 1)[1].split('} else {', 1)[0]
assert '[_m,_p] call ace_medical_treatment_fnc_canCPR' in cpr
assert '[_m,_p] call ACM_circulation_fnc_beginCPR;' in cpr
assert '_args call ACM_core_fnc_treatmentNative' not in cpr

assert 'ACME_buildBatch = "B128";' in startup
assert 'ACME_debugRevision = "rc12";' in startup

print("PASS rc12: frozen chest poses + guaranteed auscultation reservation + direct CPR callback")
