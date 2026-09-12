#!/usr/bin/env python3
"""Phase 63 regression: blast-lung ARDS latch/clock writes terminate at one gate."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class blastLungArdsCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_blastLungArdsCommit.sqf')
for key in ('ACME_blastLung_ARDS','ACME_blastLung_ardsClock'):
    assert key in commit
assert '_clear' in commit and 'ACME_fnc_setVarNet' in commit
for rel in ('fn_blastLungTick.sqf','fn_clearAllAilments.sqf'):
    assert 'ACME_fnc_blastLungArdsCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
keys='(?:ACME_blastLung_ARDS|ACME_blastLung_ardsClock)'
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_blastLungArdsCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']'+keys+r'["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and re.search(keys,code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
print('fork phase 63 blast-lung ARDS writer checks: PASS')
