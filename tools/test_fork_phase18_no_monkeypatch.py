from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
assign=re.compile(r'^\s*(?:ACM|ACME|ace)_[A-Za-z0-9_]+_fnc_[A-Za-z0-9_]+\s*=',re.M)
violations=[]
for ext in ('*.sqf','*.cpp','*.hpp'):
    for p in (ROOT/'addons').rglob(ext):
        t=p.read_text(errors='ignore')
        for m in assign.finditer(t):
            violations.append(f'{p.relative_to(ROOT)}:{t[:m.start()].count(chr(10))+1}:{m.group(0).strip()}')
assert not violations, '\n'.join(violations)
# No backup/delegate aliases remain in runtime source.
aliases=[]
for p in (ROOT/'addons').rglob('*.sqf'):
    t=p.read_text(errors='ignore')
    if 'ACME_orig_' in t or 'ACME_native_fnc_' in t:
        aliases.append(str(p.relative_to(ROOT)))
assert not aliases, aliases
print('fork phase 18 no runtime function monkey-patching checks: PASS')
