from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'
owner=FUN/'fn_thoraOutputStateCommit.sqf'
assert owner.exists()
assert 'class thoraOutputStateCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
fields=['ACME_thora_outputMl','ACME_thora_outputPerHour','ACME_thora_outputStart','ACME_thora_outputHist','ACME_thora_fluidSeen']
pat=re.compile(r'setVariable\s*\[\s*["\']('+'|'.join(map(re.escape,fields))+r')["\']')
viol=[]
for p in FUN.glob('*.sqf'):
    if p==owner: continue
    for m in pat.finditer(p.read_text(errors='ignore')): viol.append((p.name,m.group(1)))
assert not viol, viol
for n in ['fn_thoraOutput.sqf','fn_thoraPassiveDrain.sqf','fn_chestSealReset.sqf','fn_clearAllAilments.sqf','fn_clinicalReset.sqf','fn_clinicalInit.sqf']:
    assert 'ACME_fnc_thoraOutputStateCommit' in (FUN/n).read_text(errors='ignore')
print('phase85 thoracostomy output owner: PASS')
