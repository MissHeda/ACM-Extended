from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
helpers={
 'initMedicationRegistry':('fn_initMedicationRegistry.sqf','ACM_circulation_MedicationVialList'),
 'initTrainingCasualty':('fn_initTrainingCasualty.sqf','ACME_acmSpawnerPlateCarrierPFH'),
 'initInfusionConfig':('fn_initInfusionConfig.sqf','ACME_infusion_therapeuticDoseMg'),
 'initThoracostomyConfig':('fn_initThoracostomyConfig.sqf','ACME_thora_toolAnchors'),
}
for fn,(file,token) in helpers.items():
    p=ROOT/'addons/acm_extended/functions'/file
    assert p.exists(),p
    text=p.read_text()
    assert token in text,(fn,token)
    assert f'class {fn} {{}};' in CFG,fn
    assert f'call ACME_fnc_{fn};' in POST,fn
# Representative large config blocks exist only in their initializers now.
for token in ['ACM_circulation_MedicationVialList','ACME_acmSpawnerPlateCarrierPFH','ACME_infusion_therapeuticDoseMg','ACME_thora_toolAnchors']:
    assert token not in POST,token
assert len(POST.splitlines()) < 3800, len(POST.splitlines())
print('fork phase 19 postInit decomposition checks: PASS')
