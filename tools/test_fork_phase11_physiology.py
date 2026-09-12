from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CFG = (ROOT/'addons/acm_extended/config.cpp').read_text()
CORECFG = (ROOT/'addons/core/CfgFunctions.hpp').read_text()

targets = {
    'getBloodPressure': ROOT/'addons/core/overrides/fnc_getBloodPressure.sqf',
    'getBloodVolumeChange': ROOT/'addons/core/overrides/fnc_getBloodVolumeChange.sqf',
    'getCardiacOutput': ROOT/'addons/core/overrides/fnc_getCardiacOutput.sqf',
    'updateWoundBloodLoss': ROOT/'addons/core/overrides/fnc_updateWoundBloodLoss.sqf',
    'handleUnitVitals': ROOT/'addons/core/overrides/fnc_handleUnitVitals.sqf',
    'updateHeartRate': ROOT/'addons/core/overrides/fnc_updateHeartRate.sqf',
    'updateOxygen': ROOT/'addons/core/overrides/fnc_updateOxygen.sqf',
    'updatePeripheralResistance': ROOT/'addons/core/overrides/fnc_updatePeripheralResistance.sqf',
    'woundsHandlerBase': ROOT/'addons/core/overrides/fnc_woundsHandlerBase.sqf',
}
for name, path in targets.items():
    assert path.exists(), path
    assert not (ROOT/'addons/acm_extended/overrides'/f'fn_{name}.sqf').exists(), name
    assert f'overrides\\fn_{name}.sqf' not in CFG, name

assert 'class getCardiacOutput' in CORECFG
assert 'class updatePeripheralResistance' in CORECFG
assert 'ACME_native_fnc_getCardiacOutput' not in CFG
assert 'ACME_native_fnc_getCardiacOutput' not in '\n'.join(p.read_text(errors='ignore') for p in ROOT.glob('addons/**/*.sqf'))

co = targets['getCardiacOutput'].read_text()
assert 'ACME_fnc_rhythmGet' in co and 'exitWith {0}' in co
svr = targets['updatePeripheralResistance'].read_text()
for token in ['ACME_circ_resistDelta', 'ACME_flightG_resistAdd', 'ACME_vent_autoPEEP', 'ACME_resistanceApplied_tbi']:
    assert token in svr, token

print('fork phase 11 ACE physiology native merge checks: PASS')
