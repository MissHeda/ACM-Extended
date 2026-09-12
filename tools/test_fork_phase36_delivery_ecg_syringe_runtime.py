from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "registerMedicationDeliveryRuntime":("fn_registerMedicationDeliveryRuntime.sqf","ACME_fnc_medicationRetry"),
 "registerEcgJostleRuntime":("fn_registerEcgJostleRuntime.sqf","ACME_fnc_ecgJostleRequest"),
 "registerSyringeLifecycleRuntime":("fn_registerSyringeLifecycleRuntime.sqf","ACME_fnc_narcStoreCommit"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_medicationAck","ACME_ecgJostleLeaseSec","ACME_narcStore"]:
    assert token not in POST,token
assert POST.strip().endswith('call ACME_fnc_registerSyringeLifecycleRuntime;')
assert len(POST.splitlines()) < 825, len(POST.splitlines())
print("fork phase 36 delivery/ECG/syringe runtime ownership checks: PASS")
