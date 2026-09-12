from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initMinigameVentDefaults":("fn_initMinigameVentDefaults.sqf","ACME_vent_alertMVhighLpmDefault"),
 "initCardioversionSafetyConfig":("fn_initCardioversionSafetyConfig.sqf","ACME_sync_ronTvfChance"),
 "registerCompatibilityCheck":("fn_registerCompatibilityCheck.sqf","ACME_fnc_compatCheck"),
 "initMonitorSyncConfig":("fn_initMonitorSyncConfig.sqf","ACME_sync_ledPulsePeriod"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_minigame_displayMode","ACME_vent_alertLowTVeDefault","ACME_sync_ronTvfChance","ACME_fnc_compatCheck","ACME_sync_cardiovertibleRhythms","ACME_sync_ledPx"]:
    assert token not in POST,token
pos=[POST.index(f"call ACME_fnc_{fn};") for fn in helpers]
assert pos==sorted(pos),pos
assert len(POST.splitlines()) < 1320, len(POST.splitlines())
print("fork phase 30 monitor/minigame default ownership checks: PASS")
