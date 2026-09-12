from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEBUG = (ROOT / "addons/acm_extended/functions/fn_debugMenu.sqf").read_text(encoding="utf-8")
COMP = (ROOT / "addons/acm_extended/functions/fn_sedationComponents.sqf").read_text(encoding="utf-8")
TICK = (ROOT / "addons/acm_extended/functions/fn_ketamineSedationTick.sqf").read_text(encoding="utf-8")

assert "1 = configured induction" in COMP, "shared sedation contract must remain induction-normalized"
assert "private _induction = _sedLoad >= 1;" in DEBUG, "debug must use the shared normalized sedation total"
assert "_ketLoad * _adjunct >= _indThr" not in DEBUG, "debug must not apply the raw ketamine threshold twice"
assert 'format ["x%1 induction", _ketLoad toFixed 2]' in DEBUG, "ketamine debug value must identify its normalized units"
assert "private _load = [_patient] call ACME_fnc_sedationOnBoard;" in TICK
assert "_load >= (if (_owned) then {_maint} else {1})" in TICK, "worker and debug must agree that 1.0 is induction"

print("phase127 sedation debug consistency: PASS")
