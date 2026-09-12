from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "registerRoscBreathingRuntime":("fn_registerRoscBreathingRuntime.sqf","ace_medical_CPRSucceeded"),
 "registerClampDragRuntime":("fn_registerClampDragRuntime.sqf","ACME_RollerClamp_Dragging"),
 "initTbiCoreState":("fn_initTbiCoreState.sqf","ACME_tbi_activePatients"),
 "initTbiCoreConfig":("fn_initTbiCoreConfig.sqf","ACME_tbi_baseICP"),
 "registerProcedureIntegrationRuntime":("fn_registerProcedureIntegrationRuntime.sqf","ACME_infusionPulse"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ace_medical_CPRSucceeded", "ACME_RollerClamp_Dragging", "ACME_tbi_activePatients =", "ACME_tbi_baseICP =", "ACME_infusionPulse", "ACME_breathSay3D"]:
    assert token not in POST,token
assert len(POST.splitlines()) < 350, len(POST.splitlines())
print("fork phase 39 remaining clinical runtime ownership checks: PASS")
