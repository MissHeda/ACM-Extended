#!/usr/bin/env python3
"""Phase 114: every ACE requiredAddons/override target identity must exist in the supplied ACE3 baseline."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
PATCHES={x.strip().casefold() for x in (ROOT/'tools/ace_cfgpatches_manifest.txt').read_text(encoding='utf-8').splitlines() if x.strip() and not x.startswith('#')}
assert len(PATCHES)>100
used=[]
for cfg in sorted((ROOT/'addons').glob('*/config.cpp')):
    text=cfg.read_text(encoding='utf-8',errors='replace')
    m=re.search(r'requiredAddons\s*\[\]\s*=\s*\{(.*?)\}\s*;',text,re.S)
    assert m, f'missing requiredAddons in {cfg.relative_to(ROOT)}'
    for dep in re.findall(r'"([^"\r\n]+)"',m.group(1)):
        if dep.casefold().startswith('ace_'): used.append((cfg.parent.name,dep))
missing=[(owner,dep) for owner,dep in used if dep.casefold() not in PATCHES]
assert not missing, 'required ACE patches absent from supplied ACE3 baseline: '+repr(missing)
# Override tags are patch names and must also resolve upstream.
for cfg in [ROOT/'addons/core/CfgFunctions.hpp',ROOT/'addons/gui/CfgFunctions.hpp']:
    for tag in re.findall(r'\btag\s*=\s*"(ace_[A-Za-z0-9_]+)"\s*;',cfg.read_text(encoding='utf-8',errors='replace')):
        assert tag.casefold() in PATCHES, f'override tag has no supplied ACE addon: {tag}'
print(f'PASS phase114: {len(set(dep.casefold() for _,dep in used))} ACE requiredAddons identities and all override tags exist in supplied ACE3')
