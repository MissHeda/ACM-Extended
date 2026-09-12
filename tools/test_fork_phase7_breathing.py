from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
names=['Thoracostomy_closeLocal', 'Thoracostomy_insertChestTubeLocal', 'Thoracostomy_resealChestTubeLocal', 'Thoracostomy_startLocal', 'applyChestSealLocal', 'checkBreathingLocal', 'getBreathingState', 'getEtCO2', 'handlePneumothorax', 'inspectChestLocal', 'performNCDLocal', 'updateLungState', 'updateRespirationRate', 'useStethoscope']
for name in names:
    p=ROOT/"addons/breathing/functions"/f"fnc_{name}.sqf"
    assert p.exists(), p
    assert not (ROOT/"addons/acm_extended/overrides"/f"fn_{name}.sqf").exists(), name
    assert f"overrides\\fn_{name}.sqf" not in CFG, name
# retained extended behavior sentinels
assert "ACME" in (ROOT/"addons/breathing/functions/fnc_handlePneumothorax.sqf").read_text()
assert "Thoracostomy_State" in (ROOT/"addons/breathing/functions/fnc_Thoracostomy_startLocal.sqf").read_text()
assert "ACME" in (ROOT/"addons/breathing/functions/fnc_updateRespirationRate.sqf").read_text()
print("fork phase 7 breathing native merge checks: PASS")
