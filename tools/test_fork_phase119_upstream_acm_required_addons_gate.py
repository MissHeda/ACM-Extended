#!/usr/bin/env python3
"""Phase 119: native fork addons may add dependencies but must not drop upstream ACM requiredAddons."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'tools/upstream_acm_required_addons_manifest.json').read_text(encoding='utf-8'))['components']
assert len(manifest)==12
missing=[]
for component,expected in manifest.items():
    cfg=ROOT/'addons'/component/'config.cpp'
    assert cfg.is_file(), f'native ACM addon missing: {component}'
    text=cfg.read_text(encoding='utf-8',errors='replace')
    m=re.search(r'requiredAddons\s*\[\]\s*=\s*\{(.*?)\}\s*;',text,re.S)
    assert m,component
    actual={x.casefold() for x in re.findall(r'"([^"\r\n]+)"',m.group(1))}
    for dep in expected:
        if dep.casefold() not in actual: missing.append((component,dep))
assert not missing, 'fork dropped supplied upstream ACM dependencies: '+repr(missing)
print('PASS phase119: all supplied upstream ACM requiredAddons remain present across 12 native components')
