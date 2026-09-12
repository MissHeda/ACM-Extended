from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initForkStartupRuntime":("fn_initForkStartupRuntime.sqf","ACME_networkAuditRevision"),
 "registerDebugWatchdogRuntime":("fn_registerDebugWatchdogRuntime.sqf","ACME_debug_registerWatchdog"),
 "registerThoracicMenuPresentationRuntime":("fn_registerThoracicMenuPresentationRuntime.sqf","Bilateral Chest Tubes Placed"),
 "registerMedicalMenuOpenRuntime":("fn_registerMedicalMenuOpenRuntime.sqf","ace_medicalMenuOpened"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_networkAuditRevision =", "ACME_debug_registerWatchdog =", "Bilateral Chest Tubes Placed", '["ace_medicalMenuOpened", {']:
    assert token not in POST,token
assert len(POST.splitlines()) < 735, len(POST.splitlines())
print("fork phase 37 startup/menu runtime ownership checks: PASS")
