from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_medicationEscrowCommit.sqf'
assert owner.exists()
assert 'class medicationEscrowCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
pat=re.compile(r'setVariable\s*\[\s*["\']ACME_medicationEscrow["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    if pat.search(p.read_text(errors='ignore')): viol.append(p.name)
assert not viol, viol
for n in ['fn_medicationRequest.sqf','fn_medicationAck.sqf','fn_medicationRetry.sqf']:
    assert 'ACME_fnc_medicationEscrowCommit' in (FUN/n).read_text(errors='ignore')
print('phase82 medication escrow owner: PASS')
