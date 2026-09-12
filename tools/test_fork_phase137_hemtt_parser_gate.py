#!/usr/bin/env python3
"""Phase 137: HEMTT parser/build gate for first real fork build."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
errors = []

cfg = (ROOT / "addons/acm_extended/config.cpp").read_text(encoding="utf-8")
raw_safezone = re.findall(r"\b[xy]\s*=\s*safeZone[XY][^;]*;", cfg)
if raw_safezone:
    errors.append(f"acm_extended config still has {len(raw_safezone)} unquoted safeZone coordinate expressions")

if '"ACM_Vial_HTS3"' in cfg.split("class CfgPatches", 1)[1].split("};", 2)[0]:
    errors.append("stale removed ACM_Vial_HTS3 remains in ACM_Extended CfgPatches weapons[]")

defines = (ROOT / "addons/circulation/Defibrillator_defines.hpp").read_text(encoding="utf-8")
for symbol in ("IDC_LIFEPAK_MONITOR", "EKG_LINES", "EKG_DOTS", "PO_LINES", "PO_DOTS", "CO_LINES", "CO_DOTS"):
    if f"#define {symbol}" not in defines:
        errors.append(f"Defibrillator_defines.hpp is missing {symbol}")
if len(defines.splitlines()) < 2000:
    errors.append("Defibrillator_defines.hpp appears truncated")
if "ACM_UI_CANVAS_W" not in defines or "ACM_UI_CANVAS_X" not in defines:
    errors.append("LifePak aspect-safe canvas macros were lost while restoring native monitor defines")

cloud = (ROOT / "addons/cbrn/CfgCloudlets.hpp").read_text(encoding="utf-8")
if "class SmokeShellWhite;" not in cloud:
    errors.append("CfgCloudlets.hpp does not declare external SmokeShellWhite used by SMOKESHELL_ENTRY")

cbrn_cfg = (ROOT / "addons/cbrn/config.cpp").read_text(encoding="utf-8")
if re.search(r'weapons\[\]\s*=\s*\{[^}]*"ACM_Grenade_CS"', cbrn_cfg, re.S):
    errors.append("CBRN CfgPatches incorrectly lists ACM_Grenade_CS magazine as a CfgWeapons class")

if errors:
    print("FAIL phase137")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)

print("PASS phase137: first HEMTT parser failures are closed and LifePak macro surface is complete")
