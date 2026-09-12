#!/usr/bin/env python3
"""Phase 117: Extended's ACE map flashlight override must load after ace_map."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
CFG=ROOT/'addons/acm_extended/config.cpp'
text=CFG.read_text(encoding='utf-8',errors='replace')
m=re.search(r'requiredAddons\s*\[\]\s*=\s*\{(.*?)\}\s*;',text,re.S)
assert m
req={x.casefold() for x in re.findall(r'"([^"\r\n]+)"',m.group(1))}
assert 'ace_map' in req, 'ACM_Extended must load after ace_map before overriding ACE_MapFlashlight'
assert re.search(r'class\s+ACE_MapFlashlight\s*\{.*?condition\s*=.*?ACME_fnc_laryngoFlash',text,re.S), 'ACE_MapFlashlight condition override missing'
manifest={x.strip().casefold() for x in (ROOT/'tools/ace_cfgpatches_manifest.txt').read_text().splitlines() if x.strip() and not x.startswith('#')}
assert 'ace_map' in manifest, 'supplied ACE baseline unexpectedly lacks ace_map'
print('PASS phase117: Extended map-flashlight config override is ordered after supplied ace_map')
