from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CIRC=ROOT/"addons/circulation"
EXT=ROOT/"addons/acm_extended/functions"
prep=(CIRC/"XEH_PREP.hpp").read_text()
setter=(CIRC/"functions/fnc_setCardiacArrestTargetRhythm.sqf").read_text()
assert 'PREP(setCardiacArrestTargetRhythm);' in prep
assert 'setVariable [QGVAR(CardiacArrest_TargetRhythm), _rhythm, _public]' in setter
assert 'CardiacArrest_TargetRhythm_ForkPublished' in setter
viol=[]
for p in EXT.glob('*.sqf'):
    t=p.read_text()
    for line in t.splitlines():
        if 'ACM_circulation_CardiacArrest_TargetRhythm' not in line: continue
        if 'setVariable' in line: viol.append((p.name,line.strip()))
        if 'ACME_fnc_setVarNet' in line: viol.append((p.name,line.strip()))
assert not viol,viol
callers=[p.name for p in EXT.glob('*.sqf') if 'ACM_circulation_fnc_setCardiacArrestTargetRhythm' in p.read_text()]
for required in ['fn_clearAllAilments.sqf','fn_rhythmThresholdTick.sqf','fn_lidoToxTick.sqf','fn_rhythmSet.sqf','fn_arrestLocal.sqf']:
    assert required in callers,(required,callers)
print("fork phase 45 circulation target-rhythm ownership checks: PASS")
