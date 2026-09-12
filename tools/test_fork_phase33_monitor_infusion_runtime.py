from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initEmmaRuntime":("fn_initEmmaRuntime.sqf","ACME_fnc_emmaMarkContact"),
 "registerBvmVentRuntime":("fn_registerBvmVentRuntime.sqf","ACME_fnc_bvmVentTick"),
 "initAedMonitorRuntime":("fn_initAedMonitorRuntime.sqf","ACME_aedQrsBeepLockEnabled"),
 "initRhythmThresholdRuntime":("fn_initRhythmThresholdRuntime.sqf","ACME_fnc_rhythmThresholdTick"),
 "registerTransfusionUiRuntime":("fn_registerTransfusionUiRuntime.sqf","ACME_fnc_updateTransfusionControls"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_emma_holdSec","[{call ACME_fnc_bvmVentTick}, 0.04, []]","ACME_aedQrsBeepLockEnabled","[{call ACME_fnc_rhythmThresholdTick}, 0.5, []]","[{call ACME_fnc_updateTransfusionControls}, 0.05, []]"]:
    assert token not in POST,token
pos=[POST.index(f"call ACME_fnc_{fn};") for fn in helpers]
assert pos==sorted(pos),pos
assert len(POST.splitlines()) < 1080, len(POST.splitlines())
print("fork phase 33 monitor/infusion UI runtime ownership checks: PASS")
