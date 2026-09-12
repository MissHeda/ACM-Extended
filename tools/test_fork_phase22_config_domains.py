from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'initProcedurePainConfig':('fn_initProcedurePainConfig.sqf','ACME_ioInsertionMinPain'),
 'initBlastLungConfig':('fn_initBlastLungConfig.sqf','ACME_blastLung_ardsEnterSev'),
 'initFlightMotionConfig':('fn_initFlightMotionConfig.sqf','ACME_motion_vibAmplitude'),
 'initVentilatorClinicalConfig':('fn_initVentilatorClinicalConfig.sqf','ACME_vent_dyssyncRiseSec'),
 'initMedicalMenuConfig':('fn_initMedicalMenuConfig.sqf','ACME_menuGroups'),
 'initVentilatorUiPowerConfig':('fn_initVentilatorUiPowerConfig.sqf','ACME_vent_batteryMinutes'),
 'initPerfusionConfig':('fn_initPerfusionConfig.sqf','ACME_do2_normalVolume'),
 'initVentilatorRuntimeConfig':('fn_initVentilatorRuntimeConfig.sqf','ACME_vent_techCode'),
 'initFlightPhysiologyConfig':('fn_initFlightPhysiologyConfig.sqf','ACME_altitude_datumMode'),
 'initAirwayProcedureConfig':('fn_initAirwayProcedureConfig.sqf','ACME_ETT_cuffResist'),
 'initNarcBoxConfig':('fn_initNarcBoxConfig.sqf','ACME_SK_BodyHeightFrac'),
}
for fn,(file,token) in helpers.items():
    p=ROOT/'addons/acm_extended/functions'/file
    assert p.exists(),p
    text=p.read_text()
    assert token in text,(fn,token)
    assert token not in POST,(fn,token)
    assert f'class {fn} {{}};' in CFG,fn
    assert f'call ACME_fnc_{fn};' in POST,fn
# These calls should remain in their original relative order.
positions=[POST.index(f'call ACME_fnc_{fn};') for fn in helpers]
assert positions == sorted(positions),positions
# Phase 22 did not delete runtime ownership. Later phases may move registrations into explicit helpers.
RUNTIME='\n'.join(p.read_text() for p in (ROOT/'addons/acm_extended/functions').glob('*.sqf'))
for token in ['["ACM_circulation_setIVLocal", {','["ace_medical_woundReceived", {','call CBA_fnc_addPerFrameHandler']:
    assert token in RUNTIME,token
assert len(POST.splitlines()) < 2600,len(POST.splitlines())
print('fork phase 22 configuration-domain checks: PASS')
