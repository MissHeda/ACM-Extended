#!/usr/bin/env python3
"""Phase 66 regression: cumulative calcium credit has one read/modify/write endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class calciumCreditCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_calciumCreditCommit.sqf')
assert 'ACME_ca_caCl2Given' in commit and 'case "set"' in commit and '"clear"' in commit
for rel in ('fn_applyCalciumCredit.sqf','fn_administerCalcium.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_calciumCreditCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_calciumCreditCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_ca_caCl2Given["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and 'ACME_ca_caCl2Given' in code: viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
print('fork phase 66 calcium-credit writer checks: PASS')
