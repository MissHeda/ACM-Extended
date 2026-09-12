from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]; FUN=ROOT/'addons/acm_extended/functions'; O=FUN/'fn_emmaIGelStateCommit.sqf'
assert O.exists(); assert 'class emmaIGelStateCommit {};' in (ROOT/'addons/acm_extended/config.cpp').read_text(errors='ignore')
fields=['ACME_emma_igelAttached','ACME_emma_igelAttachedTime','ACME_emma_igelAttachedByUID','ACME_emma_igelAttachedByName']; pat=re.compile(r'setVariable\s*\[\s*["\']('+'|'.join(fields)+r')["\']'); viol=[]
for p in FUN.glob('*.sqf'):
    if p==O: continue
    for m in pat.finditer(p.read_text(errors='ignore')): viol.append((p.name,m.group(1)))
assert not viol, viol
print('phase89 EMMA i-gel owner: PASS')
