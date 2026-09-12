from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/"addons/acm_extended/functions"
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helper=(FUN/"fn_circStateCommit.sqf").read_text()
assert 'class circStateCommit {};' in CFG
assert 'setVariable ["ACME_circ_State", _state, _public]' in helper
viol=[]
for p in FUN.glob('*.sqf'):
    if p.name=='fn_circStateCommit.sqf': continue
    t=p.read_text()
    if 'setVariable ["ACME_circ_State"' in t: viol.append((p.name,'direct'))
    if '["ACME_circ_State", _state]' in t and 'ACME_fnc_setVarNet' in t: viol.append((p.name,'setVarNet'))
assert not viol,viol
callers=[p.name for p in FUN.glob('*.sqf') if 'ACME_fnc_circStateCommit' in p.read_text()]
for required in ['fn_circHandle.sqf','fn_toggleShock.sqf','fn_epinephrineBolusLocal.sqf','fn_clinicalReset.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf']:
    assert required in callers,(required,callers)
print("fork phase 43 circulation authoritative writer checks: PASS")
