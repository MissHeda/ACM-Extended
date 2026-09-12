from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POST = (ROOT / "addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG = (ROOT / "addons/acm_extended/config.cpp").read_text()
helpers = {
    "registerClinicalLifecycleRuntime": ("fn_registerClinicalLifecycleRuntime.sqf", "ace_medical_FullHeal"),
    "initHeadAirwayRuntime": ("fn_initHeadAirwayRuntime.sqf", "ACME_fnc_ettMigrate"),
}
for fn, (filename, token) in helpers.items():
    text = (ROOT / "addons/acm_extended/functions" / filename).read_text()
    assert token in text, (fn, token)
    assert f"class {fn} {{}};" in CFG, fn
    assert f"call ACME_fnc_{fn};" in POST, fn
for token in [
    "ace_medical_FullHeal",
    "ACME_ySalineSetup",
    "ACME_fnc_ettMigrate",
    "ACME_ejBodyMarkX",
    "ACME_CS_inflictPneumo",
]:
    assert token not in POST, token
assert POST.index("call ACME_fnc_registerClinicalLifecycleRuntime;") < POST.index("call ACME_fnc_initBloodStorageRuntime;") < POST.index("call ACME_fnc_initHeadAirwayRuntime;")
assert len(POST.splitlines()) < 1700, len(POST.splitlines())
print("fork phase 26 clinical/airway runtime ownership checks: PASS")
