#!/usr/bin/env python3
"""Phase 77 regression: blast-lung episode metadata has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class blastLungEpisodeCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_blastLungEpisodeCommit.sqf')
for name in ('ACME_blastLung_exposures','ACME_blastLung_Onset','ACME_blastLung_Time'): assert name in commit
for rel in ('fn_blastLungInflict.sqf','fn_registerBlastLungRuntime.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    assert 'ACME_fnc_blastLungEpisodeCommit' in read('addons/acm_extended/functions/'+rel), rel
pat=r'ACME_blastLung_(?:exposures|Onset|Time)'
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_blastLungEpisodeCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']'+pat+r'["\']',code) or ('ACME_fnc_setVarNet' in code and re.search(pat,code)): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
assert '_blastEpisodeRestore' in read('addons/acm_extended/functions/fn_clinicalRestore.sqf')
print('fork phase 77 blast-lung episode writer checks: PASS')
