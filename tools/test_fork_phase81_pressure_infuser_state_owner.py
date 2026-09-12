from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_pressureInfuserStateCommit.sqf'
assert owner.exists()
assert 'class pressureInfuserStateCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
pat=re.compile(r'setVariable\s*\[\s*["\'](ACME_piCuffs|ACME_piReceipts)["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    for m in pat.finditer(p.read_text(errors='ignore')): viol.append((p.name,m.group(1)))
assert not viol, viol
for n in ['fn_pressureInfuserCommit.sqf','fn_pressureInfuserTick.sqf']:
    assert 'ACME_fnc_pressureInfuserStateCommit' in (FUN/n).read_text(errors='ignore')
print('phase81 pressure infuser owner: PASS')
