#!/usr/bin/env python3
"""RC11 regression: chest access opens directly, restores carriers visibly, parks props safely, and keeps XStat art."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

treatment = read("addons/core/overrides/fnc_treatment.sqf")
acquire = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
restore = read("addons/acm_extended/functions/fn_chestAccessVestRestore.sqf")
event = read("addons/acm_extended/functions/fn_chestAccessVestEvent.sqf")
cs_end = read("addons/acm_extended/functions/fn_chestSealPatientEnd.sqf")
cs_close = read("addons/acm_extended/functions/fn_chestSealClose.sqf")
park = read("addons/acm_extended/functions/fn_chestAccessVestPark.sqf")
cs_park = read("addons/acm_extended/functions/fn_chestSealParkCarrier.sqf")
pose_start = read("addons/acm_extended/functions/fn_treatmentPoseStart.sqf")
pose_stop = read("addons/acm_extended/functions/fn_treatmentPoseStop.sqf")
junction = read("addons/acm_extended/functions/fn_updateJunctionalImage.sqf")
startup = read("addons/acm_extended/functions/fn_initForkStartupRuntime.sqf")

# Carrier prep cannot hand back while either the pose controller or outer roll-provider token still owns the medic.
assert 'private _providerReady = (_pose isEqualTo [])' in treatment
assert 'ACME_rollProviderActive' in treatment

# Auscultation reserves a real continuous-action generation, then opens the scope directly after chest prep.
steth = treatment.split('if (_classKey == "usestethoscope") then {', 1)[1].split('} else {\n                if (_classKey == "cpr")', 1)[0]
assert 'private _entryEpoch = (missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", 0]) + 1;' in steth
assert '[_m,_p,_bodyPart,true,_entryEpoch] call ACM_breathing_fnc_useStethoscope;' in steth
assert 'CBA_fnc_execNextFrame' in steth
assert 'ace_medical_treatment_fnc_treatment' not in steth

# CPR revalidates canCPR and calls the configured beginCPR callback directly after chest prep.
cpr = treatment.split('if (_classKey == "cpr") then {', 1)[1].split('} else {', 1)[0]
assert '[_m,_p] call ace_medical_treatment_fnc_canCPR' in cpr
assert '[_m,_p] call ACM_circulation_fnc_beginCPR;' in cpr
assert '_args call ACM_core_fnc_treatmentNative' not in cpr

# Reverse restoration is literally lift -> vest on -> patient release in the animated path.
animated = restore.split('// Provider mirrors the original removal theatre', 1)[1]
assert animated.index('"ACME_HeadElevPatientGrab"') < animated.index('setUnitLoadout') < animated.index('"ACME_HeadElevPatientRelease"')
assert '[_medic,"chestAccessVestProvider",[_medic,_patient,"chestAccessVestRestore"]]' in restore

# Ordinary chest access and chest seal both use the shared animated restoration path with provider identity.
assert '[_patient, false, _medic, "access"] call ACME_fnc_chestAccessVestRestore;' in event
assert '[_p,false,_medic,"chestseal"] call ACME_fnc_chestAccessVestRestore;' in cs_end
assert '[_patient, _sessionToken, _flipMedic]' in cs_close

# Removed carriers are parked immediately and continuously, for both custody systems, beyond a larger head gap.
assert 'ACME_CS_vestPFH' in acquire
assert '0.10' in acquire
assert 'ACME_chestAccessCarrierGap' in park
assert 'ACME_chestAccessCarrierGap' in cs_park
assert '0.62' in park and '0.62' in cs_park

# Provider work uses the known-good exact priority-1 entry so finite chest RTMs reliably reach their freeze stage.
main = pose_start.split('private _fnStartMain = {', 1)[1].split('// Crouch first.', 1)[0]
assert '[_medic, _main, 1] call ACME_fnc_doAnim;' in main
freeze = pose_start.split('// Freeze the owner on the frame it naturally reached.', 1)[1].split('private _jip', 1)[0]
assert '_medic switchMove [_main, _phase, 1, false];' not in freeze
assert '_medic setAnimSpeedCoef 0;' in freeze

# XStat returns to the proven original wound-control path; the extra packing control is combat gauze only.
assert 'if (_state == "xstat") then {_xstatTex} else {_openTex}' in junction
assert '_packedC ctrlShow (_state == "packed");' in junction

assert 'ACME_buildBatch = "B128";' in startup
assert 'ACME_debugRevision = "rc12";' in startup

print("PASS rc12: chest lifecycle + reverse carrier restore + head clearance + XStat image")
