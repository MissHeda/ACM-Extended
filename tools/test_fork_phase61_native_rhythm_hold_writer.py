#!/usr/bin/env python3
"""Phase 61 regression: native rhythm hold kind/rhythm pair has one mutation endpoint."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
assert 'class rhythmNativeHoldCommit {};' in read('addons/acm_extended/config.cpp')
commit=read('addons/acm_extended/functions/fn_rhythmNativeHoldCommit.sqf')
for key in ('ACME_rhythmNativeHoldKind','ACME_rhythmNativeHoldRhythm'):
    assert key in commit
assert 'if (_kind isEqualTo "") then {_rhythm = -1;};' in commit
for rel in ('fn_rhythmThresholdTick.sqf','fn_shockLocal.sqf','fn_registerRhythmLifecycleRuntime.sqf','fn_rhythmSet.sqf','fn_clearAllAilments.sqf'):
    assert 'ACME_fnc_rhythmNativeHoldCommit' in read('addons/acm_extended/functions/'+rel), rel
clear=read('addons/acm_extended/functions/fn_clearAllAilments.sqf')
assert '"ACME_rhythmNativeHoldKind", "ACME_rhythmNativeHoldRhythm"' not in clear
viol=[]
keys='(?:ACME_rhythmNativeHoldKind|ACME_rhythmNativeHoldRhythm)'
for p in FUN.rglob('*.sqf'):
    if p.name=='fn_rhythmNativeHoldCommit.sqf': continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']'+keys+r'["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and re.search(keys,code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
print('fork phase 61 native-rhythm hold writer checks: PASS')
