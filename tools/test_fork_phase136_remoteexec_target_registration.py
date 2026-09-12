#!/usr/bin/env python3
"""Phase 136: CfgRemoteExec entries point at real registered fork functions and persistent dispatch stays explicit."""
import re
from pathlib import Path
R=Path(__file__).resolve().parents[1]
config=(R/'addons/acm_extended/config.cpp').read_text()
remote=config[config.index('class CfgRemoteExec'):]
entries=set(re.findall(r'class\s+((?:ACME_fnc_|ACM_airway_fnc_)\w+)\s*\{', remote))
# ACME functions are registered by class name in the Extended CfgFunctions block.
for name in sorted(n for n in entries if n.startswith('ACME_fnc_')):
    short=name[len('ACME_fnc_'):]
    assert re.search(r'\bclass\s+'+re.escape(short)+r'\s*\{', config), name
    assert (R/'addons/acm_extended/functions'/f'fn_{short}.sqf').is_file(), name
# The one native ACM remote endpoint remains airway-owned and PREPed there.
if 'ACM_airway_fnc_remoteSay3D' in entries:
    assert 'PREP(remoteSay3D);' in (R/'addons/airway/XEH_PREP.hpp').read_text()
    assert (R/'addons/airway/functions/fnc_remoteSay3D.sqf').is_file()
# Only the cooler visual scale call is intentionally persistent/JIP in active fork source.
jip_refs=[]
for p in (R/'addons').rglob('*.sqf'):
    for line in p.read_text(errors='ignore').splitlines():
        if 'remoteExec' in line and 'ACME_fnc_' in line and ', _box]' in line:
            jip_refs.append((p,line))
assert any('ACME_fnc_coolerBoxApplyScale' in line for _,line in jip_refs)
print(f'PASS phase136: {len(entries)} named CfgRemoteExec entries resolve to registered fork functions')
