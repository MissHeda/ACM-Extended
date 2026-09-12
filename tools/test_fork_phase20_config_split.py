from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'initCirculationConfig':('fn_initCirculationConfig.sqf','ACME_circ_shockInitialSeverity'),
 'initConsciousnessConfig':('fn_initConsciousnessConfig.sqf','ACME_obtunded_fixedAnim'),
 'initIVProcedureConfig':('fn_initIVProcedureConfig.sqf','ACME_iv_armEdgeStart'),
 'initPatientPositioningConfig':('fn_initPatientPositioningConfig.sqf','ACME_headElev_icpDropPerSec'),
 'initMegacodeConfig':('fn_initMegacodeConfig.sqf','ACME_megacode_restAnim'),
 'initDrugPhysiologyConfig':('fn_initDrugPhysiologyConfig.sqf','ACME_infusion_pressorOnsetSec'),
}
for fn,(file,token) in helpers.items():
    p=ROOT/'addons/acm_extended/functions'/file
    assert p.exists(),p
    text=p.read_text()
    assert token in text,(fn,token)
    assert f'class {fn} {{}};' in CFG,fn
    assert f'call ACME_fnc_{fn};' in POST,fn
    assert token not in POST,(fn,token)
# Calls must preserve the original domain order around the TBI runtime registration.
order=[POST.index(f'call ACME_fnc_{fn};') for fn in helpers]
assert order == sorted(order), order
assert POST.index('call ACME_fnc_initDrugPhysiologyConfig;') < POST.index('call ACME_fnc_registerTbiRuntime;')
assert len(POST.splitlines()) < 3250, len(POST.splitlines())
print('fork phase 20 config-domain decomposition checks: PASS')
