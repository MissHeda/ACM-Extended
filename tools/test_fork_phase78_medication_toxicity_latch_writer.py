#!/usr/bin/env python3
"""Phase 78 regression: medication-toxicity generation latch has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class medicationToxicityFiredCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_medicationToxicityFiredCommit.sqf')
assert 'ACME_medicationToxicityFired' in commit and 'createHashMapFromArray' in commit
for rel in ('fn_medicationExposure.sqf','fn_medicationToxicityTick.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_medicationToxicityFiredCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_medicationToxicityFiredCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_medicationToxicityFired["\']',code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
assert '_toxicityFiredRestoreSet' in read('addons/acm_extended/functions/fn_clinicalRestore.sqf')
print('fork phase 78 medication-toxicity latch writer checks: PASS')
