#!/usr/bin/env python3
"""Static contract check for the IV site name/index handoff.

The minigame stores peripheral sites as strings. ACM body-map and circulation paths also use
numeric site indexes. Helpers shared by both paths must accept both shapes.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
name_file = ROOT / "functions" / "fn_skSiteName.sqf"
set_file = ROOT / "functions" / "fn_ivVeinSet.sqf"
init_file = ROOT / "functions" / "fn_ivMinigameInit.sqf"

name = name_file.read_text(encoding="utf-8")
veinset = set_file.read_text(encoding="utf-8")
init = init_file.read_text(encoding="utf-8")

checks = []
def check(label, ok):
    checks.append((label, bool(ok)))

check("skSiteName recognizes String sites", '_site isEqualType ""' in name)
for site, idx in (("upper", 0), ("middle", 1), ("lower", 2)):
    check(f"skSiteName maps {site} to {idx}", f'case "{site}": {{ {idx} }};' in name)
check("skSiteName has no raw String-unsafe site clamp", "select (_site max" not in name)
check("ivVeinSet still uses named site state", "private _s = toLower _site;" in veinset)
check("ivVeinSet may pass named site to skSiteName", "[_bp, _s, false] call ACME_fnc_skSiteName" in veinset)
check("IV init passes its named active site into ivVeinSet", "_site, _veinU, _veinV] call ACME_fnc_ivVeinSet" in init)

failed = [label for label, ok in checks if not ok]
for label, ok in checks:
    print(("PASS " if ok else "FAIL ") + label)
print(f"{len(checks) - len(failed)}/{len(checks)} checks passed")
if failed:
    sys.exit(1)
