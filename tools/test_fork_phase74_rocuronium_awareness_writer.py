#!/usr/bin/env python3
"""Phase 74 regression: awake-paralysis awareness outcome has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class rocAwarenessStateCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_rocAwarenessStateCommit.sqf')
for name in ('ACME_roc_awarenessEvent','ACME_roc_awarenessAt','ACME_roc_awarenessSeconds'):
    assert name in commit
assert 'ACME_fnc_setVarNet' in commit
for rel in ('fn_rocuroniumTick.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_rocAwarenessStateCommit' in read('addons/acm_extended/functions/'+rel), rel
pat=r'ACME_roc_awareness(?:Event|At|Seconds)'
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_rocAwarenessStateCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']'+pat+r'["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and re.search(pat,code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
assert '_rocAwarenessRestore' in read('addons/acm_extended/functions/fn_clinicalRestore.sqf')
print('fork phase 74 rocuronium awareness writer checks: PASS')
