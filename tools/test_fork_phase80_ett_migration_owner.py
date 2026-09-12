from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_ettMigrationStateCommit.sqf'
assert owner.exists()
assert 'class ettMigrationStateCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
fields=['ACME_ETT_Depth','ACME_ETT_Frame','ACME_ETT_Mainstem','ACME_ETT_Obstructing','ACME_ETT_ObstructUntil']
pat=re.compile(r'setVariable\s*\[\s*["\']('+'|'.join(map(re.escape,fields))+r')["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    for m in pat.finditer(p.read_text(errors='ignore')): viol.append((p.name,m.group(1)))
assert not viol, viol
for n in ['fn_laryngoPassTube.sqf','fn_laryngoTubeEject.sqf','fn_laryngoExtubate.sqf','fn_ettMigrate.sqf']:
    assert 'ACME_fnc_ettMigrationStateCommit' in (FUN/n).read_text(errors='ignore')
print('phase80 ett migration owner: PASS')
