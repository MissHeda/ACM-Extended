#!/usr/bin/env python3
from pathlib import Path
R=Path(__file__).resolve().parents[1]
p=R/'tools/validate_fork.py'
assert p.is_file()
t=p.read_text(encoding='utf-8',errors='replace')
for token in ('test_fork_phase','structural_scan','commands = [[exe, "check"]]','commands.append([exe, "build"])','--min-phase','--max-phase','--hemtt','--build'):
    assert token in t, token
assert 'class aajtStateCommit {};' in (R/'addons/acm_extended/config.cpp').read_text(errors='replace')
print('fork phase 92 unified validation harness checks: PASS')
