from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
checks={
 'gui_native': ROOT/'addons/gui/functions/fnc_getBodyPartIVBags.sqf',
 'airway_native': ROOT/'addons/airway/functions/fnc_getAirwayState.sqf',
 'aed_native': ROOT/'addons/circulation/functions/fnc_recentAEDShock.sqf',
}
for name,p in checks.items():
    assert p.exists(), (name,p)
assert 'overrides\\fn_getBodyPartIVBags.sqf' not in CFG
assert 'overrides\\fn_getAirwayState.sqf' not in CFG
assert 'overrides\\fn_recentAEDShock.sqf' not in CFG
for old in ('fn_getBodyPartIVBags.sqf','fn_getAirwayState.sqf','fn_recentAEDShock.sqf'):
    assert not (ROOT/'addons/acm_extended/overrides'/old).exists(), old
assert 'ACME_SalineY' in checks['gui_native'].read_text()
assert 'ACME_ETT_Inserted' in checks['airway_native'].read_text()
assert 'ACME_aed_postShockWindow' in checks['aed_native'].read_text()
print('fork phase 1 native merge checks: PASS')
