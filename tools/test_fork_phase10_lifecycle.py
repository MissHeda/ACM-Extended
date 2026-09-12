from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
targets={'resetVariables':ROOT/'addons/core/functions/fnc_resetVariables.sqf','onUnconscious':ROOT/'addons/core/functions/fnc_onUnconscious.sqf','serializeState':ROOT/'addons/core/overrides/fnc_serializeState.sqf','deserializeState':ROOT/'addons/core/overrides/fnc_deserializeState.sqf','handleEffects':ROOT/'addons/core/overrides/fnc_handleEffects.sqf'}
for old,p in targets.items():
    assert p.exists(), p
    assert not (ROOT/'addons/acm_extended/overrides'/f'fn_{old}.sqf').exists(), old
    assert f'overrides\\fn_{old}.sqf' not in CFG, old
assert 'ACME_clinicalRestoring' in targets['onUnconscious'].read_text()
assert 'ACME_Clinical_v3' in targets['serializeState'].read_text()
assert 'ACME_Clinical_v3' in targets['deserializeState'].read_text()
assert 'ACME_rollProviderActive' in targets['resetVariables'].read_text()
assert 'ACME_rhythm_painContribution' in targets['handleEffects'].read_text()
print('fork phase 10 lifecycle native merge checks: PASS')
