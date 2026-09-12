#!/usr/bin/env python3
"""Phase 65 regression: rocuronium paralysis has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class rocParalysisCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_rocParalysisCommit.sqf')
assert 'ACME_roc_paralyzed' in commit and 'ACME_fnc_setVarNet' in commit
for rel in ('fn_rocuroniumTick.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_rocParalysisCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_rocParalysisCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_roc_paralyzed["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and 'ACME_roc_paralyzed' in code: viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
print('fork phase 65 rocuronium-paralysis writer checks: PASS')
