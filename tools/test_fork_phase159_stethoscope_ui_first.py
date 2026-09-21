#!/usr/bin/env python3
"""RC14 regression: auscultation UI exists before any provider/patient presentation can consume the action."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
use_steth = read("addons/breathing/functions/fnc_useStethoscope.sqf")
begin = read("addons/acm_extended/functions/fn_beginStethoscopeAction.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

steth = treatment.split('if (_classKey == "usestethoscope") then {', 1)[1].split('} else {\n                if (_classKey == "cpr")', 1)[0]
assert 'missionNamespace setVariable ["ACM_core_ContinuousAction_Active",false];' in steth
assert '[_m,_p,_bodyPart,true] call ACM_breathing_fnc_useStethoscope;' in steth
assert '_entryEpoch' not in steth

onstart = use_steth.split('[[_medic, _patient, _bodyPart], {  // on start.', 1)[1].split('}, {  // on cancel.', 1)[0]
assert onstart.index('createDialog "ACM_breathing_Stethoscope_Dialog";') < onstart.index('ACME_fnc_ownerDispatch')
assert onstart.index('createDialog "ACM_breathing_Stethoscope_Dialog";') < onstart.index('ACME_fnc_patientAnimRequest')
assert onstart.index('ACME_fnc_stethoscopeInit') < onstart.index('ACME_fnc_ownerDispatch')
assert 'Unable to open auscultation display.' in onstart

open_first = begin.split('// The minigame is the clinical action; provider animation is presentation.', 1)[1].split('private _dialogKeyEH', 1)[0]
assert open_first.index('_args call _onStart;') < open_first.index('ACME_fnc_treatmentPoseStart')
assert 'private _scopeOpened' in open_first
assert 'ACM_core_ContinuousAction_LastSeen' in begin

assert 'ACME_buildBatch = "B130";' in startup
assert 'ACME_debugRevision = "rc14";' in startup

print("PASS rc14: stethoscope panel opens before presentation and uses normal unreserved controller startup")
