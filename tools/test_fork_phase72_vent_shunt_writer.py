#!/usr/bin/env python3
"""Phase 72 regression: ventilator-derived shunt has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class ventShuntCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_ventShuntCommit.sqf')
assert 'ACME_vent_shunt' in commit
for rel in ('fn_ventOxygenation.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_ventShuntCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_ventShuntCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_vent_shunt["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and 'ACME_vent_shunt' in code: viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
assert '_ventShuntRestoreSet' in read('addons/acm_extended/functions/fn_clinicalRestore.sqf')
print('fork phase 72 ventilator-shunt writer checks: PASS')
