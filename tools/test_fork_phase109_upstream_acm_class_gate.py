#!/usr/bin/env python3
"""Phase 109: preserve directly declared upstream ACM_* config classes."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "addons"
MANIFEST = ROOT / "tools/upstream_acm_class_manifest.txt"


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)

expected = {
    line.strip().casefold()
    for line in MANIFEST.read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
}
assert len(expected) == 163, f"unexpected upstream ACM class manifest size: {len(expected)}"

actual = set()
for source in ADDONS.rglob("*"):
    if not source.is_file() or source.suffix.lower() not in {".hpp", ".cpp", ".h"}:
        continue
    text = strip_comments(source.read_text(encoding="utf-8", errors="ignore"))
    actual.update(match.group(1).casefold() for match in re.finditer(r"\bclass\s+(ACM_[A-Za-z0-9_]+)\b", text, re.I))

missing = sorted(expected - actual)
assert not missing, "fork removed upstream ACM config classes:\n" + "\n".join(missing)
assert len(actual) >= len(expected)

print(f"PASS phase109: {len(expected)} upstream ACM config classes preserved; fork directly declares {len(actual)} ACM_* classes")
