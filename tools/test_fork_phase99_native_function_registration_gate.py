#!/usr/bin/env python3
"""Phase 99: validate native ACM PREP registrations and explicit CfgFunctions sources."""
from __future__ import annotations
from collections import Counter
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "addons"


def main() -> None:
    missing: list[str] = []
    duplicates: list[str] = []
    prep_count = 0
    explicit_cfg_count = 0

    for prep in sorted(ADDONS.glob("*/XEH_PREP.hpp")):
        text = prep.read_text(encoding="utf-8", errors="replace")
        names = re.findall(r"\bPREP\(([^)]+)\)\s*;", text)
        prep_count += len(names)
        for name, count in Counter(names).items():
            if count > 1:
                duplicates.append(f"{prep.relative_to(ROOT)}: PREP({name}) x{count}")
            source = prep.parent / "functions" / f"fnc_{name}.sqf"
            if not source.is_file():
                missing.append(f"{prep.relative_to(ROOT)}: PREP({name}) -> {source.relative_to(ROOT)}")

    # Core/GUI compile-time ACE overrides use explicit QPATHTOF(...) file entries rather than PREP.
    for cfg in sorted(ADDONS.glob("*/CfgFunctions.hpp")):
        text = cfg.read_text(encoding="utf-8", errors="replace")
        for raw in re.findall(r"\bfile\s*=\s*QPATHTOF\(([^)]+)\)\s*;", text):
            explicit_cfg_count += 1
            rel = raw.strip().replace("\\", "/")
            source = cfg.parent / Path(rel)
            if not source.is_file():
                missing.append(f"{cfg.relative_to(ROOT)}: QPATHTOF({raw}) -> {source.relative_to(ROOT)}")

    assert not duplicates, "duplicate native PREP registrations:\n" + "\n".join(duplicates)
    assert not missing, "missing native function sources:\n" + "\n".join(missing[:100])
    assert prep_count > 300, f"unexpectedly low native PREP count: {prep_count}"
    assert explicit_cfg_count > 30, f"unexpectedly low explicit CfgFunctions source count: {explicit_cfg_count}"
    print(
        f"fork phase 99 native function-registration gate: PASS "
        f"({prep_count} PREP registrations, {explicit_cfg_count} explicit CfgFunctions sources)"
    )


if __name__ == "__main__":
    main()
