from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
checks={
 'initResuscitationConfig':('fn_initResuscitationConfig.sqf',['ACME_ca_citrateThreshold','ACME_edema_threshold','ACME_circ_pushDoseMAPcap']),
 'initTbiProgressionConfig':('fn_initTbiProgressionConfig.sqf',['ACME_tbi_vitalsCushICP','ACME_tbi_recoverMAPmin','ACME_tbi_globalRiseCapPerSec']),
}
for fn,(file,tokens) in checks.items():
    text=(ROOT/'addons/acm_extended/functions'/file).read_text()
    assert f'class {fn} {{}};' in CFG
    assert f'call ACME_fnc_{fn};' in POST
    for token in tokens:
        assert token in text,(fn,token)
        assert token not in POST,(fn,token)
assert POST.index('call ACME_fnc_initResuscitationConfig;') < POST.index('call ACME_fnc_initIVProcedureConfig;')
assert POST.index('call ACME_fnc_initMegacodeConfig;') < POST.index('call ACME_fnc_initTbiProgressionConfig;')
assert POST.index('call ACME_fnc_initTbiProgressionConfig;') < POST.index('call ACME_fnc_initDrugPhysiologyConfig;')
assert len(POST.splitlines()) < 3050, len(POST.splitlines())
print('fork phase 21 physiology-config ownership checks: PASS')
