from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'; O=FUN/'fn_openVialStoreCommit.sqf'
assert O.exists(); assert 'class openVialStoreCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
pat=re.compile(r'setVariable\s*\[\s*["\']ACME_infusion_openVials["\']'); viol=[]
for p in FUN.glob('*.sqf'):
    if p!=O and pat.search(p.read_text(errors='ignore')): viol.append(p.name)
assert not viol, viol
print('phase88 open vial owner: PASS')
