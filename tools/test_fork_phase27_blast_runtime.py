from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
POST=(ROOT/"addons/acm_extended/functions/fn_postInit.sqf").read_text()
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
P=ROOT/"addons/acm_extended/functions/fn_initBlastOverpressureRuntime.sqf"
assert P.exists()
text=P.read_text()
for token in ["ACME_tbi_blastTriggerDamage", "ProjectileCreated", "ACME_blastDetonated", "ACME_bloodTypeLock", "CBA_fnc_addClassEventHandler"]:
    assert token in text, token
    assert token not in POST, token
assert "class initBlastOverpressureRuntime {};" in CFG
assert "call ACME_fnc_initBlastOverpressureRuntime;" in POST
assert len(POST.splitlines()) < 1600, len(POST.splitlines())
print("fork phase 27 blast-overpressure runtime ownership checks: PASS")
