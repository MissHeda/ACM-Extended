from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CORECFG=(ROOT/'addons/core/CfgFunctions.hpp').read_text()
COREPATCH=(ROOT/'addons/core/config.cpp').read_text()
# No remaining runtime monkey-patches in postInit.
pat=re.compile(r'^\s*(?:ACM|ACME|ace)_[A-Za-z0-9_]+_fnc_[A-Za-z0-9_]+\s*=',re.M)
assert not pat.search(POST), pat.findall(POST)
for tok in ['ACME_orig_generatePatient','ACME_orig_canConvert','ACME_orig_insertAirwayItem','ACME_orig_addToLog','ACME_orig_displayTextStructured','ACME_orig_progressBar','ACME_orig_getBloodPressure']:
    assert tok not in POST,tok
assert 'ACME_runtimeOverrideStatus' not in POST
assert '"ace_common"' in COREPATCH
assert 'class addToLog' in CORECFG and 'class overwrite_ace_common' in CORECFG
for rel,tok in [
 ('addons/mission/functions/fnc_generatePatient.sqf','ACME_pendingSpawnSeverity'),
 ('addons/evacuation/functions/fnc_canConvert.sqf','ACME_surgicalCasualty'),
 ('addons/airway/functions/fnc_insertAirwayItem.sqf','ACME_lido_seizureState'),
 ('addons/core/overrides/fnc_addToLog.sqf','ACME_fnc_ivLogRelabel'),
 ('addons/core/overrides/fnc_displayTextStructured.sqf','ACME_fnc_clinTerm'),
 ('addons/core/overrides/fnc_progressBar.sqf','ACME_DP_treatTimeMult')]:
    assert tok in (ROOT/rel).read_text(),(rel,tok)
for rel in ['addons/acm_extended/functions/fn_circHandle.sqf','addons/acm_extended/functions/fn_toggleShock.sqf']:
    t=(ROOT/rel).read_text(); assert 'ACME_fnc_bpNative' in t and 'ACME_orig_getBloodPressure' not in t
print('fork phase 17 compile-time ownership checks: PASS')
