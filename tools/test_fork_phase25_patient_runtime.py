from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POST = (ROOT / 'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG = (ROOT / 'addons/acm_extended/config.cpp').read_text()

helpers = {
    'registerChestSealPresenceRuntime': ('fn_registerChestSealPresenceRuntime.sqf', 'ACME_CS_presenceLeave'),
    'registerHpmkTransportCleanupRuntime': ('fn_registerHpmkTransportCleanupRuntime.sqf', 'ACME_hpmkKillBlanket'),
    'initHypothermiaRuntime': ('fn_initHypothermiaRuntime.sqf', 'ACME_fnc_hypothermiaTick'),
    'registerMedicalBodyBaseRuntime': ('fn_registerMedicalBodyBaseRuntime.sqf', 'ACME_fnc_junctionalGuiSyncTick'),
    'initBloodStorageRuntime': ('fn_initBloodStorageRuntime.sqf', 'ACME_fnc_bloodColdChainTick'),
}

for fn, (filename, token) in helpers.items():
    path = ROOT / 'addons/acm_extended/functions' / filename
    assert path.exists(), path
    text = path.read_text()
    assert token in text, (fn, token)
    assert f'class {fn} {{}};' in CFG, fn
    assert f'call ACME_fnc_{fn};' in POST, fn

for token in [
    'ACME_CS_presenceLeave',
    'ACME_hpmkKillBlanket',
    'ACME_hypo_coolTickSec',
    'ACME_fnc_junctionalGuiSyncTick',
    'ACME_bfViewPing',
    'ACME_bloodScanInterval',
]:
    assert token not in POST, token

positions = [POST.index(f'call ACME_fnc_{fn};') for fn in helpers]
assert positions == sorted(positions), positions
assert len(POST.splitlines()) < 1800, len(POST.splitlines())
print('fork phase 25 patient-facing runtime ownership checks: PASS')
