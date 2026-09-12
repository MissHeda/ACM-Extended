from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
for name in ['getMedicationCount','ivBagLocal','medicationLocal','onMedicationUsage','tourniquetRemove']:
    native=ROOT/f'addons/core/overrides/fnc_{name}.sqf'
    assert native.exists(),native
    assert not (ROOT/f'addons/acm_extended/overrides/fn_{name}.sqf').exists(),name
    assert f'overrides\\fn_{name}.sqf' not in CFG,name
assert 'ACME_fnc_medicationAvailability' in (ROOT/'addons/core/overrides/fnc_getMedicationCount.sqf').read_text()
raw=(ROOT/'addons/acm_extended/functions/fn_medicationCountRaw.sqf').read_text()
assert 'ACME_fnc_medicationAvailability' not in raw
assert 'class medicationCountRaw {};' in CFG
suga=(ROOT/'addons/acm_extended/functions/fn_sugammadexTick.sqf').read_text()
assert 'ACME_fnc_medicationCountRaw' in suga and 'ACME_native_fnc_getMedicationCount' not in suga
assert 'ACME_native_fnc_getMedicationCount' not in CFG
print('fork phase 13 medication native merge checks: PASS')
