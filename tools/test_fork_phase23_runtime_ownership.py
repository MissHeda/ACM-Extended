from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'registerTbiRuntime':('fn_registerTbiRuntime.sqf','ACME_fnc_tbiHandle'),
 'registerBlastLungRuntime':('fn_registerBlastLungRuntime.sqf','ace_medical_woundReceived'),
 'registerCirculationRuntime':('fn_registerCirculationRuntime.sqf','ACME_fnc_salineAcidosisTrack'),
 'registerVentilatorAudioRuntime':('fn_registerVentilatorAudioRuntime.sqf','ACME_ventSndFade'),
 'initNrbRuntime':('fn_initNrbRuntime.sqf','ACME_fnc_nrbTick'),
}
for fn,(file,token) in helpers.items():
    p=ROOT/'addons/acm_extended/functions'/file
    assert p.exists(),p
    text=p.read_text()
    assert token in text,(fn,token)
    assert f'class {fn} {{}};' in CFG,fn
    assert f'call ACME_fnc_{fn};' in POST,fn
# Registration code for these domains must no longer be inline in postInit.
for token in ['[{call ACME_fnc_tbiHandle}','["ace_medical_woundReceived", {','[{call ACME_fnc_salineAcidosisTrack}','["ACME_ventSndFade", {','[{call ACME_fnc_nrbTick}']:
    assert token not in POST,token
positions=[POST.index(f'call ACME_fnc_{fn};') for fn in helpers]
assert positions == sorted(positions),positions
assert len(POST.splitlines()) < 2300,len(POST.splitlines())
print('fork phase 23 runtime ownership checks: PASS')
