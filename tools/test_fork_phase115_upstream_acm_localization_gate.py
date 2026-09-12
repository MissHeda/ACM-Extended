#!/usr/bin/env python3
"""Phase 115: preserve every upstream ACM localization key in its owning native component."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'tools/upstream_acm_stringtable_manifest.json').read_text(encoding='utf-8'))['components']
expected_total=sum(len(v) for v in manifest.values())
assert expected_total==1068
missing=[]
for component,ids in manifest.items():
    st=ROOT/'addons'/component/'stringtable.xml'
    assert st.is_file(), f'upstream component stringtable missing: {component}'
    actual={x.casefold() for x in re.findall(r'<Key\s+ID="([^"]+)"',st.read_text(encoding='utf-8',errors='replace'),re.I)}
    for key in ids:
        if key.casefold() not in actual: missing.append((component,key))
assert not missing, 'fork removed upstream ACM localization keys:\n'+'\n'.join(f'{c}: {k}' for c,k in missing)
print(f'PASS phase115: all {expected_total} supplied upstream ACM localization keys remain in their native components')
