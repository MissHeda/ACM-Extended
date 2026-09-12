from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'registerRhythmLifecycleRuntime':('fn_registerRhythmLifecycleRuntime.sqf','EntityRespawned'),
 'registerInfusionProcessingRuntime':('fn_registerInfusionProcessingRuntime.sqf','ACME_fnc_handleInfusions'),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/'addons/acm_extended/functions'/file).read_text()
    assert token in text,(fn,token)
    assert f'class {fn} {{}};' in CFG
    assert f'call ACME_fnc_{fn};' in POST
for token in ['[{call ACME_fnc_rhythmTick}, 0.5, []]','addMissionEventHandler ["EntityRespawned"','ACME_rhythmNativeShockGraceUntil','[{[] call ACME_fnc_syncPremixedBags}, 1, []]','[{call ACME_fnc_handleInfusions}, 0.25, []]']:
    assert token not in POST,token
assert POST.index('call ACME_fnc_registerRhythmLifecycleRuntime;') < POST.index('call ACME_fnc_registerInfusionProcessingRuntime;')
assert len(POST.splitlines()) < 1140,len(POST.splitlines())
print('fork phase 32 rhythm/lifecycle runtime ownership checks: PASS')
