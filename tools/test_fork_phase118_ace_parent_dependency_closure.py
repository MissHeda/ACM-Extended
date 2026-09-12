#!/usr/bin/env python3
"""Phase 118: ACE_* config inheritance parents must be available through the owner's ACE dependency closure."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
GRAPH=json.loads((ROOT/'tools/ace_cfgpatches_dependency_manifest.json').read_text(encoding='utf-8'))['patches']
PARENTS=json.loads((ROOT/'tools/ace_parent_class_owner_manifest.json').read_text(encoding='utf-8'))['parents']
parent_ci={k.casefold():{x.casefold() for x in v} for k,v in PARENTS.items()}

def clean(t):
    t=re.sub(r'/\*.*?\*/',' ',t,flags=re.S)
    return re.sub(r'//[^\n]*',' ',t)

def closure(seed):
    out=set(); stack=[x for x in seed if x.casefold().startswith('ace_')]
    graph={k.casefold():[x.casefold() for x in v if x.casefold().startswith('ace_')] for k,v in GRAPH.items()}
    while stack:
        x=stack.pop().casefold()
        if x in out: continue
        out.add(x); stack.extend(graph.get(x,[]))
    return out

missing=[]; uses=0
for addon in sorted((ROOT/'addons').iterdir()):
    if not addon.is_dir() or not (addon/'config.cpp').is_file(): continue
    cfg=(addon/'config.cpp').read_text(encoding='utf-8',errors='replace')
    m=re.search(r'requiredAddons\s*\[\]\s*=\s*\{(.*?)\}\s*;',cfg,re.S)
    assert m,addon
    req=re.findall(r'"([^"\r\n]+)"',m.group(1))
    available=closure(req)
    for p in addon.rglob('*'):
        if not p.is_file() or p.suffix.lower() not in {'.hpp','.cpp','.h'}: continue
        text=clean(p.read_text(encoding='utf-8',errors='replace'))
        for mm in re.finditer(r'\bclass\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*(ACE_[A-Za-z0-9_]+)',text,re.I):
            parent=mm.group(1); owners=parent_ci.get(parent.casefold())
            assert owners, f'ACE parent absent from supplied class-owner manifest: {parent}'
            uses+=1
            if not (owners & available):
                missing.append((addon.name,str(p.relative_to(addon)),parent,sorted(owners)))
assert not missing, 'ACE config inheritance parent is not ordered before fork addon:\n'+ '\n'.join(map(str,missing))
assert uses>=90
print(f'PASS phase118: {uses} ACE config inheritance uses resolve through supplied ACE dependency closure')
