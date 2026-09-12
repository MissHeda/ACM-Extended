#!/usr/bin/env python3
"""Unified ACM Extended fork validation harness.

Runs repository phase tests in numeric order, performs comment/string-aware SQF/config
structure checks, and can optionally invoke HEMTT when it is installed.
"""
from __future__ import annotations
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHASE_RE = re.compile(r"test_fork_phase(\d+)")


def phase_tests(min_phase: int, max_phase: int) -> list[tuple[int, Path]]:
    out: list[tuple[int, Path]] = []
    for p in (ROOT / "tools").glob("test_fork_phase*.py"):
        m = PHASE_RE.search(p.name)
        if not m:
            continue
        phase = int(m.group(1))
        if min_phase <= phase <= max_phase:
            out.append((phase, p))
    return sorted(out, key=lambda x: (x[0], x[1].name.lower()))


def latest_phase() -> int:
    phases: list[int] = []
    for p in (ROOT / "tools").glob("test_fork_phase*.py"):
        m = PHASE_RE.search(p.name)
        if m:
            phases.append(int(m.group(1)))
    if not phases:
        raise RuntimeError("no fork phase tests found")
    return max(phases)


def run_phase_tests(min_phase: int, max_phase: int) -> tuple[int, int]:
    tests = phase_tests(min_phase, max_phase)
    if not tests:
        raise RuntimeError(f"no phase tests found in {min_phase}-{max_phase}")
    passed = 0
    for phase, path in tests:
        rel = path.relative_to(ROOT)
        proc = subprocess.run(
            [sys.executable, str(path)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        text = proc.stdout.strip()
        if text:
            print(text)
        if proc.returncode != 0:
            raise RuntimeError(f"phase {phase} test failed: {rel}")
        passed += 1
    return passed, len(tests)


def strip_comments_and_strings(text: str) -> str:
    out: list[str] = []
    i = 0
    state = "code"
    quote = ""
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ""
        if state == "line":
            if c == "\n":
                state = "code"
                out.append("\n")
            else:
                out.append(" ")
        elif state == "block":
            if c == "*" and n == "/":
                out.extend("  ")
                state = "code"
                i += 1
            else:
                out.append("\n" if c == "\n" else " ")
        elif state == "string":
            # SQF/config strings use doubled quote characters for an embedded quote. Backslashes are path
            # separators, not C/Python-style escapes (many valid texture paths end in a backslash).
            if c == quote and n == quote:
                out.extend("  ")
                i += 1
            elif c == quote:
                out.append(" ")
                state = "code"
            else:
                out.append("\n" if c == "\n" else " ")
        else:
            if c == "/" and n == "/":
                out.extend("  ")
                state = "line"
                i += 1
            elif c == "/" and n == "*":
                out.extend("  ")
                state = "block"
                i += 1
            elif c in ('"', "'"):
                quote = c
                state = "string"
                out.append(" ")
            else:
                out.append(c)
        i += 1
    if state in {"block", "string"}:
        raise ValueError(f"unterminated {state}")
    return "".join(out)


def structural_scan() -> tuple[int, int]:
    sqf = sorted(ROOT.glob("addons/**/*.sqf"))
    cfg = sorted(ROOT.glob("addons/**/config.cpp"))
    pairs = {"(": ")", "[": "]", "{": "}"}
    closers = {v: k for k, v in pairs.items()}
    failures: list[str] = []
    for p in [*sqf, *cfg]:
        try:
            clean = strip_comments_and_strings(p.read_text(encoding="utf-8", errors="replace"))
        except ValueError as exc:
            failures.append(f"{p.relative_to(ROOT)}: {exc}")
            continue
        stack: list[tuple[str, int]] = []
        line = 1
        for c in clean:
            if c == "\n":
                line += 1
                continue
            if c in pairs:
                stack.append((c, line))
            elif c in closers:
                if not stack or stack[-1][0] != closers[c]:
                    failures.append(f"{p.relative_to(ROOT)}:{line}: unexpected {c}")
                    break
                stack.pop()
        else:
            if stack:
                failures.append(f"{p.relative_to(ROOT)}:{stack[-1][1]}: unclosed {stack[-1][0]}")
    if failures:
        raise RuntimeError("structural scan failed:\n" + "\n".join(failures[:50]))
    print(f"structural scan: PASS ({len(sqf)} SQF, {len(cfg)} config.cpp)")
    return len(sqf), len(cfg)


def find_hemtt(explicit: str | None) -> str | None:
    if explicit:
        p = Path(explicit)
        if p.is_file():
            return str(p.resolve())
        found = shutil.which(explicit)
        return found
    local = ROOT / "hemtt"
    if local.is_file():
        return str(local)
    return shutil.which("hemtt")


def run_hemtt(exe: str, build: bool) -> None:
    commands = [[exe, "check"]]
    if build:
        commands.append([exe, "build"])
    for cmd in commands:
        print("running:", " ".join(cmd))
        proc = subprocess.run(cmd, cwd=ROOT)
        if proc.returncode != 0:
            raise RuntimeError(f"HEMTT command failed with exit {proc.returncode}: {' '.join(cmd)}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-phase", type=int, default=1)
    ap.add_argument("--max-phase", type=int, default=None, help="highest phase to run; defaults to the latest discovered phase test")
    ap.add_argument("--skip-tests", action="store_true")
    ap.add_argument("--skip-structural", action="store_true")
    ap.add_argument("--hemtt", nargs="?", const="hemtt", help="run HEMTT check; optionally provide executable path")
    ap.add_argument("--build", action="store_true", help="with --hemtt, also run `hemtt build`")
    args = ap.parse_args()
    max_phase = latest_phase() if args.max_phase is None else args.max_phase
    if args.min_phase > max_phase:
        ap.error("--min-phase cannot exceed --max-phase/latest discovered phase")
    if not args.skip_tests:
        passed, total = run_phase_tests(args.min_phase, max_phase)
        print(f"phase regression suite: PASS ({passed}/{total})")
    if not args.skip_structural:
        structural_scan()
    if args.hemtt is not None:
        exe = find_hemtt(args.hemtt)
        if not exe:
            raise RuntimeError("HEMTT requested but no executable was found")
        run_hemtt(exe, args.build)
    print("fork validation: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"fork validation: FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
