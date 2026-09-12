from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'registerConsciousnessRuntime':('fn_registerConsciousnessRuntime.sqf','ACME_fnc_consciousnessBudget'),
 'registerProviderStanceReleaseRuntime':('fn_registerProviderStanceReleaseRuntime.sqf','setUnitPos "AUTO"'),
 'registerHeadElevationTransportRuntime':('fn_registerHeadElevationTransportRuntime.sqf','ACME_headElev_transportDown'),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/'addons/acm_extended/functions'/file).read_text()
    assert token in text,(fn,token)
    assert f'class {fn} {{}};' in CFG
    assert f'call ACME_fnc_{fn};' in POST
for token in ['ACME_fnc_obtundedTick','ACME_fnc_consciousnessBudget','ACME_beingTreated_until','setUnitPos "AUTO"','ACME_headElev_transportDown']:
    assert token not in POST,token
pos=[POST.index(f'call ACME_fnc_{fn};') for fn in helpers]
assert pos==sorted(pos),pos
assert len(POST.splitlines()) < 1210,len(POST.splitlines())
print('fork phase 31 consciousness/provider runtime ownership checks: PASS')
