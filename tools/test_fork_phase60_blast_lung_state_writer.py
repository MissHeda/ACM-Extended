#!/usr/bin/env python3
"""Phase 60 regression: blast-lung severity has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class blastLungStateCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_blastLungStateCommit.sqf')
assert 'ACME_blastLung_State' in commit
assert 'ACME_fnc_setVarNet' in commit and 'setVariable' in commit and '_clear' in commit
for rel in ('fn_blastLungInflict.sqf','fn_blastLungTick.sqf','fn_clearAllAilments.sqf'):
    assert 'ACME_fnc_blastLungStateCommit' in read('addons/acm_extended/functions/'+rel), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_blastLungStateCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_blastLung_State["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and re.search(r'ACME_blastLung_State',code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
print('fork phase 60 blast-lung state-writer checks: PASS')
