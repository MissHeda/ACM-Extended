from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
for token in ['class ACME_overwrite_','class ACME_native','class overwrite_medical_gui','class overwrite_medical_status','class overwrite_medical_treatment','class overwrite_ace_dragging','class overwrite_ace_dogtags']:
    assert token not in CFG,token
shock=(ROOT/'addons/circulation/functions/fnc_AED_AdministerShock.sqf').read_text()
assert 'ACME_fnc_ownerDispatch' in shock and 'ACME_shockSequence' in shock
et=(ROOT/'addons/breathing/functions/fnc_getEtCO2.sqf').read_text()
assert 'ACME_native_fnc_getEtCO2' not in et
assert 'GET_AIRWAYSTATE' in et and 'GET_BREATHINGSTATE' in et
assert 'ACME_vent_mvAdequacy' in et and 'ACME_vent_cprBadTime' in et
sqf='\n'.join(p.read_text(errors='ignore') for p in ROOT.glob('addons/**/*.sqf'))
assert 'ACME_native_fnc_' not in sqf
print('fork phase 16 override scaffolding removal checks: PASS')
