#!/usr/bin/env python3
"""Phase 71 regression: native-rhythm recovery clocks have authoritative mutation endpoints."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
def read(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='replace')
cfg=read('addons/acm_extended/config.cpp')
assert 'class rhythmNativeHighHRFloorCommit {};' in cfg
assert 'class rhythmNativeShockGraceCommit {};' in cfg
floor=read('addons/acm_extended/functions/fn_rhythmNativeHighHRFloorCommit.sqf')
grace=read('addons/acm_extended/functions/fn_rhythmNativeShockGraceCommit.sqf')
assert 'ACME_rhythmNativeHighHRFloorUntil' in floor and 'ACME_fnc_setVarNet' in floor
assert 'ACME_rhythmNativeShockGraceUntil' in grace
for rel in ('fn_rhythmThresholdTick.sqf','fn_rhythmSet.sqf','fn_shockLocal.sqf','fn_registerRhythmLifecycleRuntime.sqf','fn_clearAllAilments.sqf','fn_clinicalRestore.sqf','fn_clinicalReset.sqf'):
    txt=read('addons/acm_extended/functions/'+rel)
    assert ('ACME_fnc_rhythmNativeHighHRFloorCommit' in txt or 'ACME_fnc_rhythmNativeShockGraceCommit' in txt), rel
viol=[]
for p in FUN.rglob('*.sqf'):
    if p.name in {'fn_rhythmNativeHighHRFloorCommit.sqf','fn_rhythmNativeShockGraceCommit.sqf'}: continue
    for i,raw in enumerate(p.read_text(encoding='utf-8',errors='replace').splitlines(),1):
        code=raw.split('//',1)[0]
        if re.search(r'setVariable\s*\[\s*["\']ACME_rhythmNative(?:HighHRFloorUntil|ShockGraceUntil)["\']',code): viol.append((p,i,raw.strip()))
        if 'ACME_fnc_setVarNet' in code and re.search(r'ACME_rhythmNative(?:HighHRFloorUntil|ShockGraceUntil)',code): viol.append((p,i,raw.strip()))
assert not viol, '\n'.join(f'{p.relative_to(ROOT)}:{i}: {s}' for p,i,s in viol)
restore=read('addons/acm_extended/functions/fn_clinicalRestore.sqf')
assert '_rhythmTimingRestore' in restore
print('fork phase 71 native-rhythm timing writer checks: PASS')
