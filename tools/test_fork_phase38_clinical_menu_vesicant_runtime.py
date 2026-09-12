from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "registerClinicalMenuPresentationRuntime":("fn_registerClinicalMenuPresentationRuntime.sqf","ACME_ivLastSite"),
 "initVesicantRuntime":("fn_initVesicantRuntime.sqf","ACME_vesicant_table"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_ivLastSite", "ACME_vesicant_enabled =", "ACME_vesicant_table =", "ACME_fnc_vesicantTick"]:
    assert token not in POST,token
assert len(POST.splitlines()) < 470, len(POST.splitlines())
print("fork phase 38 clinical-menu/vesicant runtime ownership checks: PASS")
