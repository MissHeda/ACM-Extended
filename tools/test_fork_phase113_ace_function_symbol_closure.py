#!/usr/bin/env python3
"""Phase 113: every ACE function symbol referenced by fork source must resolve to ACE or a fork override."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
BASE={x.strip().casefold() for x in (ROOT/'tools/ace_public_function_manifest.txt').read_text(encoding='utf-8').splitlines() if x.strip() and not x.startswith('#')}


def strip_comments(text:str)->str:
    out=[];i=0;state='code';quote=''
    while i<len(text):
        c=text[i];n=text[i+1] if i+1<len(text) else ''
        if state=='line':
            if c=='\n':state='code';out.append('\n')
            else:out.append(' ')
        elif state=='block':
            if c=='*' and n=='/':out.extend('  ');state='code';i+=1
            else:out.append('\n' if c=='\n' else ' ')
        elif state=='string':
            out.append(c)
            if c==quote and n==quote:out.append(n);i+=1
            elif c==quote:state='code'
        else:
            if c=='/' and n=='/':out.extend('  ');state='line';i+=1
            elif c=='/' and n=='*':out.extend('  ');state='block';i+=1
            elif c in ('"',"'"):state='string';quote=c;out.append(c)
            else:out.append(c)
        i+=1
    return ''.join(out)

# Fork-owned ACE CfgFunctions overrides are valid public symbols too. Phase 112 freezes this map.
import json
override_manifest=json.loads((ROOT/'tools/ace_override_target_manifest.json').read_text(encoding='utf-8'))['targets']
overrides={f"{x['tag']}_fnc_{x['function']}".casefold() for x in override_manifest}

refs=set()
for p in (ROOT/'addons').rglob('*'):
    if not p.is_file() or p.suffix.lower() not in {'.sqf','.hpp','.cpp'}: continue
    text=strip_comments(p.read_text(encoding='utf-8',errors='replace'))
    refs.update(x.casefold() for x in re.findall(r'\b(ace_[A-Za-z0-9_]+_fnc_[A-Za-z0-9_]+)\b',text))

missing=sorted(refs-(BASE|overrides))
assert not missing, 'unresolved ACE function symbols:\n'+'\n'.join(missing)
assert len(refs)>=70, f'ACE reference scan unexpectedly small: {len(refs)}'
print(f'PASS phase113: {len(refs)} referenced ACE function symbols resolve to supplied ACE PREP API or fork compile-time overrides')
