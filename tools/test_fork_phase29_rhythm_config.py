from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helpers={
 "initRhythmTriggerConfig":("fn_initRhythmTriggerConfig.sqf","ACME_rhythm_torsadesCaSevere"),
 "initPressureAndAuscultationConfig":("fn_initPressureAndAuscultationConfig.sqf","ACME_DP_treatTimeMult"),
 "initRhythmHemodynamicsConfig":("fn_initRhythmHemodynamicsConfig.sqf","ACME_rhythm_acmProxy"),
}
for fn,(file,token) in helpers.items():
    text=(ROOT/"addons/acm_extended/functions"/file).read_text()
    assert token in text,(fn,token)
    assert f"class {fn} {{}};" in CFG
    assert f"call ACME_fnc_{fn};" in POST
for token in ["ACME_rhythmPressorSurgeEnabled","ACME_edema_crackleFastVol","ACME_DP_fracturePainEnabled","ACME_rhythm_perfusingCustom","ACME_rhythm_acmProxy"]:
    assert token not in POST,token
assert len(POST.splitlines()) < 1380, len(POST.splitlines())
print("fork phase 29 rhythm/direct-pressure configuration ownership checks: PASS")
