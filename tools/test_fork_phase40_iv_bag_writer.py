from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/"addons/acm_extended/functions"
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helper=(FUN/"fn_ivBagsCommit.sqf").read_text()
assert 'class ivBagsCommit {};' in CFG
assert 'ACM_circulation_fnc_setIVBagsState' in helper
# Extended code must cross one mutation gate for the native IV-bag map.
direct=[]
for p in FUN.glob('*.sqf'):
    t=p.read_text()
    if 'setVariable ["ACM_circulation_IV_Bags"' in t and p.name != 'fn_ivBagsCommit.sqf':
        direct.append(p.name)
assert not direct, direct
callers=[p.name for p in FUN.glob('*.sqf') if 'ACME_fnc_ivBagsCommit' in p.read_text()]
assert len(callers) >= 10, callers
for required in [
 'fn_discardYTubing.sqf','fn_transfusionPullBag.sqf','fn_ySalineSetup.sqf','fn_preparedAttachLocal.sqf',
 'fn_hangPreparedSet.sqf','fn_infusionRegisterCore.sqf','fn_transfusionSpikeOrAdd.sqf','fn_yLineAttach.sqf',
 'fn_bagIdentity.sqf','fn_updateTransfusionControls.sqf']:
    assert required in callers,required
print("fork phase 40 IV-bag authoritative writer checks: PASS")
