from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initJunctionalConfig":("fn_initJunctionalConfig.sqf","ACME_junctionalGauzeControl"),
 "initChestSealProcedureRuntime":("fn_initChestSealProcedureRuntime.sqf","ACME_CS_woundTable"),
 "registerInjuryPresentationRuntime":("fn_registerInjuryPresentationRuntime.sqf","ACME_fnc_junctionalInjuryEntry"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG,fn
    assert f"call ACME_fnc_{fn};" in POST,fn
for token in ["ACME_junctionalGauzeControl","ACME_CS_woundTable","ACME_fnc_junctionalInjuryEntry","ACME_fnc_cyanosisHideInjury"]:
    assert token not in POST,token
pos=[POST.index(f"call ACME_fnc_{fn};") for fn in helpers]
assert pos==sorted(pos),pos
assert len(POST.splitlines()) < 1480, len(POST.splitlines())
print("fork phase 28 trauma configuration/presentation ownership checks: PASS")
