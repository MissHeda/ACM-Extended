#!/usr/bin/env python3
"""Phase 100: require unique ACM/ACME localization ownership and direct-reference closure."""
from __future__ import annotations
from collections import defaultdict
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXT = {".sqf", ".cpp", ".hpp", ".inc"}


def main() -> None:
    by_key: dict[str, list[tuple[str, Path]]] = defaultdict(list)
    tables = sorted(ROOT.glob("addons/**/stringtable.xml"))
    assert tables, "no stringtables found"

    for table in tables:
        tree = ET.parse(table)  # XML well-formedness is part of the gate.
        for node in tree.getroot().iter("Key"):
            key = node.attrib.get("ID", "").strip()
            assert key, f"empty stringtable Key ID in {table.relative_to(ROOT)}"
            if key.upper().startswith(("STR_ACM_", "STR_ACME_")):
                by_key[key.casefold()].append((key, table))

    dup = {k: v for k, v in by_key.items() if len(v) > 1}
    assert not dup, "duplicate ACM/ACME localization IDs: " + repr(
        {k: [(raw, str(p.relative_to(ROOT))) for raw, p in vals] for k, vals in list(dup.items())[:50]}
    )

    missing: list[str] = []
    direct_refs = 0
    localize_re = re.compile(r'\blocalize\s+"(STR_(?:ACM|ACME)_[A-Za-z0-9_]+)"', re.I)
    dollar_re = re.compile(r'"\$(STR_(?:ACM|ACME)_[A-Za-z0-9_]+)"', re.I)

    for path in sorted(ROOT.glob("addons/**/*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for kind, rx in (("localize", localize_re), ("$STR", dollar_re)):
            for match in rx.finditer(text):
                key = match.group(1)
                direct_refs += 1
                if key.casefold() not in by_key:
                    line = text.count("\n", 0, match.start()) + 1
                    missing.append(f"{path.relative_to(ROOT)}:{line}: {kind} {key}")

    assert not missing, "missing direct ACM/ACME localization keys:\n" + "\n".join(missing[:100])

    # Preserve the effective English wording from the former Extended override, now at the native owner.
    airway = ET.parse(ROOT / "addons/airway/stringtable.xml").getroot()
    expected = {
        "STR_ACM_Airway_CheckAirway_AirwayIsClear",
        "STR_ACM_Airway_Suction_AirwayIsClear",
        "STR_ACM_Airway_HeadTurn_AirwayIsClear",
    }
    values = {}
    for node in airway.iter("Key"):
        kid = node.attrib.get("ID")
        if kid in expected:
            english = node.find("English")
            values[kid] = "" if english is None else (english.text or "")
    assert set(values) == expected, values
    assert all(v == "Airway is patent" for v in values.values()), values

    print(
        f"fork phase 100 localization-closure gate: PASS "
        f"({len(tables)} stringtables, {len(by_key)} unique ACM/ACME keys, {direct_refs} direct refs)"
    )


if __name__ == "__main__":
    main()
