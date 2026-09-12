from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
targets={
 'aedAnalyzeRhythm':ROOT/'addons/circulation/functions/fnc_AED_AnalyzeRhythm.sqf',
 'aedButtonShock':ROOT/'addons/circulation/functions/fnc_AED_Button_Shock.sqf',
 'genCO':ROOT/'addons/circulation/functions/fnc_displayAEDMonitor_generateCO.sqf',
 'genEKG':ROOT/'addons/circulation/functions/fnc_displayAEDMonitor_generateEKG.sqf',
 'genPO':ROOT/'addons/circulation/functions/fnc_displayAEDMonitor_generatePO.sqf',
 'checkPulseLocal':ROOT/'addons/core/overrides/fnc_checkPulseLocal.sqf',
}
for old,p in targets.items():
    assert p.exists(), p
    assert not (ROOT/'addons/acm_extended/overrides'/f'fn_{old}.sqf').exists(), old
    assert f'overrides\\fn_{old}.sqf' not in CFG, old
assert 'ACME_sync_defibrillatableRhythms' in targets['aedAnalyzeRhythm'].read_text()
assert 'ACME_fnc_shockRequest' in targets['aedButtonShock'].read_text()
assert 'ACME_fnc_genRhythmEKG' in targets['genEKG'].read_text()
assert 'ACME_fnc_aajtOccludes' in targets['checkPulseLocal'].read_text()
print('fork phase 9 monitor native merge checks: PASS')
