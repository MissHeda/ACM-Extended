from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_thoraSideStateCommit.sqf'
assert owner.exists()
assert 'class thoraSideStateCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
pat=re.compile(r'setVariable\s*\[\s*format\s*\[\s*["\']ACME_thora_(incision|incisionScore|prep|infection|open|ribTarget|site|tube|sealed)_%1["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    if pat.search(p.read_text(errors='ignore')): viol.append(p.name)
assert not viol, viol
# explicit sealed left/right should also be gone
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    txt=p.read_text(errors='ignore')
    assert 'setVariable ["ACME_thora_sealed_left"' not in txt
    assert 'setVariable ["ACME_thora_sealed_right"' not in txt
print('phase84 thoracostomy side state owner: PASS')
