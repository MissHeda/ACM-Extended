#!/usr/bin/env python3
"""Phase 107: preserve explicit metadata for ACE compatibility boundaries owned by the fork."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "addons/core/CfgFunctions.hpp").read_text(encoding="utf-8", errors="ignore")
AMBIENT = (ROOT / "addons/acm_extended/functions/fn_ambientTemp.sqf").read_text(encoding="utf-8", errors="ignore")

# getBloodVolumeChange is intentionally retained under the ACE public symbol even though the supplied
# ACE3 baseline no longer ships a same-named source function. Keep that exceptional ownership explicit.
assert "Fork-retained compatibility function" in CORE
assert re.search(r'class\s+getBloodVolumeChange\s*\{.*?fnc_getBloodVolumeChange\.sqf', CORE, re.S)
assert 'tag = "ace_medical_status";' in CORE

# The ambient helper must target the weather API exposed by the supplied ACE3 baseline.
assert "ace_weather_fnc_calculateTemperatureAtHeight" in AMBIENT
assert not re.search(r"\bace_weather_fnc_calculateTemperature\b", AMBIENT)

print("PASS phase107: explicit ACE compatibility ownership and current weather API contract")
