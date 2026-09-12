from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BREATH=ROOT/"addons/breathing"
EXT=ROOT/"addons/acm_extended/functions"
prep=(BREATH/"XEH_PREP.hpp").read_text()
setter=(BREATH/"functions/fnc_setChestInjuryState.sqf").read_text()
assert 'PREP(setChestInjuryState);' in prep
assert 'setVariable [QGVAR(ChestInjury_State), _state, true]' in setter
# Extended may read this native state, but every Extended write must cross the breathing-owned API.
violations=[]
for p in EXT.glob('*.sqf'):
    t=p.read_text()
    if 'setVariable ["ACM_breathing_ChestInjury_State"' in t:
        violations.append((p.name,'setVariable'))
    if '[_patient, "ACM_breathing_ChestInjury_State"' in t and 'ACME_fnc_setVarNet' in t:
        violations.append((p.name,'setVarNet'))
    if '[_patient,"ACM_breathing_ChestInjury_State"' in t and 'ACME_fnc_setVarNet' in t:
        violations.append((p.name,'setVarNet'))
assert not violations,violations
callers=[p.name for p in EXT.glob('*.sqf') if 'ACM_breathing_fnc_setChestInjuryState' in p.read_text()]
for required in ['fn_megacodeChestInjury.sqf','fn_initHeadAirwayRuntime.sqf','fn_blastLungInflict.sqf','fn_ptxInjury.sqf','fn_ventDriveTick.sqf']:
    assert required in callers,(required,callers)
print("fork phase 41 breathing chest-injury ownership checks: PASS")
