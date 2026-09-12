#!/usr/bin/env python3
from pathlib import Path
import importlib.util

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "tools" / "validate_fork.py"
spec = importlib.util.spec_from_file_location("validate_fork", path)
assert spec and spec.loader
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

latest = mod.latest_phase()
assert latest >= 95, latest
selected = mod.phase_tests(95, latest)
assert any(p.name == "test_fork_phase95_latest_phase_discovery.py" for _, p in selected)
text = path.read_text(encoding="utf-8", errors="replace")
assert 'default=None' in text
assert 'latest_phase() if args.max_phase is None' in text
assert 'default=92' not in text
print(f"fork phase 95 latest-phase discovery checks: PASS (latest={latest})")
