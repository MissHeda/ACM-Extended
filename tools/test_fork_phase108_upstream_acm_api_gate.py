#!/usr/bin/env python3
"""Phase 108: the fork must remain a superset of the supplied upstream ACM PREP API."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "addons"
MANIFEST = ROOT / "tools/upstream_acm_prep_manifest.txt"


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)

expected = {
    line.strip().casefold()
    for line in MANIFEST.read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
}
assert len(expected) == 348, f"unexpected upstream ACM manifest size: {len(expected)}"

actual = set()
for prep in ADDONS.rglob("XEH_PREP.hpp"):
    component = prep.parent.name
    component_header = prep.parent / "script_component.hpp"
    if component_header.exists():
        match = re.search(
            r"^\s*#define\s+COMPONENT\s+([A-Za-z0-9_]+)",
            component_header.read_text(encoding="utf-8", errors="ignore"),
            re.M,
        )
        if match:
            component = match.group(1)
    text = strip_comments(prep.read_text(encoding="utf-8", errors="ignore"))
    for function in re.findall(r"\bPREP\s*\(\s*([A-Za-z0-9_]+)\s*\)", text):
        actual.add(f"ACM_{component}_fnc_{function}".casefold())

missing = sorted(expected - actual)
assert not missing, "fork removed upstream ACM PREP API symbols:\n" + "\n".join(missing)
assert len(actual) >= len(expected), "fork PREP API unexpectedly smaller than upstream manifest"

print(f"PASS phase108: {len(expected)} upstream ACM PREP symbols preserved; fork exposes {len(actual)} native PREP symbols")
