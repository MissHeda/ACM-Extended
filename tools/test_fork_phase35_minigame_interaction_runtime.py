from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "registerVentilatorKeybindRuntime":("fn_registerVentilatorKeybindRuntime.sqf","ACME_vent_dialPress"),
 "initMinigameInteractionRuntime":("fn_initMinigameInteractionRuntime.sqf","ACME_flashlightMenuActive"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_vent_dialPress","ACME_minigameDisplays","ACME_vent_flipDevice","ace_common_fnc_addCanInteractWithCondition","ACME_flashlightMenuActive"]:
    assert token not in POST,token
assert len(POST.splitlines()) < 850, len(POST.splitlines())
print("fork phase 35 minigame interaction ownership checks: PASS")
