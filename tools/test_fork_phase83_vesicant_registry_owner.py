from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_vesicantRegistryCommit.sqf'
assert owner.exists()
assert 'class vesicantRegistryCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
pat=re.compile(r'setVariable\s*\[\s*["\'](ACME_vesicant_records|ACME_vesicant_patients_dirty)["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    for m in pat.finditer(p.read_text(errors='ignore')): viol.append((p.name,m.group(1)))
assert not viol, viol
for n in ['fn_vesicantInjure.sqf','fn_vesicantReverse.sqf','fn_clearAllAilments.sqf']:
    assert 'ACME_fnc_vesicantRegistryCommit' in (FUN/n).read_text(errors='ignore')
print('phase83 vesicant registry owner: PASS')
