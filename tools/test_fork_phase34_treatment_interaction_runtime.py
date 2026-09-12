from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initHardcoreRuntime":("fn_initHardcoreRuntime.sqf","ACME_hcReady"),
 "registerTreatmentRollRuntime":("fn_registerTreatmentRollRuntime.sqf","ACME_fnc_rollProviderStart"),
 "registerHeadElevationTreatmentRuntime":("fn_registerHeadElevationTreatmentRuntime.sqf","ACME_fnc_headElevTreatmentEvent"),
 "registerMegacodeInteractionRuntime":("fn_registerMegacodeInteractionRuntime.sqf","ACME_MegacodeControl"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_hcReady = true","ACME_fnc_rollProviderStart","ACME_headElev_treatmentSerial","ACME_MegacodeControl"]:
    assert token not in POST,token
pos=[POST.index(f"call ACME_fnc_{fn};") for fn in helpers]
assert pos==sorted(pos),pos
assert len(POST.splitlines()) < 1020, len(POST.splitlines())
print("fork phase 34 treatment/interaction runtime ownership checks: PASS")
