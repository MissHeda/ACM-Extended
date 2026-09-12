#!/usr/bin/env python3
"""Phase 110: preserve upstream ACM native addon PBO namespaces exactly."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools/upstream_acm_pboprefix_manifest.txt"

expected = {}
for line in MANIFEST.read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    component, prefix = line.split("=", 1)
    expected[component] = prefix

assert len(expected) == 12, f"unexpected native PBO prefix manifest size: {len(expected)}"

for component, prefix in sorted(expected.items()):
    prefix_file = ROOT / "addons" / component / "$PBOPREFIX$"
    assert prefix_file.exists(), f"missing $PBOPREFIX$ for native addon {component}"
    actual = prefix_file.read_text(encoding="utf-8", errors="ignore").strip()
    assert actual == prefix, f"PBO prefix drift for {component}: expected {prefix!r}, got {actual!r}"

extended = (ROOT / "addons/acm_extended/$PBOPREFIX$").read_text(encoding="utf-8", errors="ignore").strip()
assert extended == "acm_extended", f"unexpected Extended PBO prefix: {extended!r}"

print(f"PASS phase110: {len(expected)} upstream ACM PBO prefixes preserved; Extended keeps {extended!r}")
