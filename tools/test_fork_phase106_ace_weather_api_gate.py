#!/usr/bin/env python3
"""Phase 106: pin ACME ambient-temperature integration to the supplied ACE weather API."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "addons/acm_extended/functions/fn_ambientTemp.sqf"
text = SRC.read_text(encoding="utf-8", errors="ignore")

assert "ace_weather_fnc_calculateTemperatureAtHeight" in text, "ambient temp must use ACE calculateTemperatureAtHeight"
# The removed ACE API name must not survive as a callable token. The longer current name is excluded by the boundary.
assert not re.search(r"\bace_weather_fnc_calculateTemperature\b", text), "obsolete ACE calculateTemperature API still referenced"
assert re.search(r"\(_posASL\s+select\s+2\).*call\s+ace_weather_fnc_calculateTemperatureAtHeight", text, re.S), \
    "ACE temperature-at-height call must receive ASL height as a scalar"
assert "ace_weather_currentTemperature" in text, "ACE current-temperature fast path must remain"
assert "ACME_ambientTempC" in text, "mission temperature override must remain highest-priority path"

print("PASS phase106: ambient temperature uses the supplied ACE weather temperature-at-height API")
