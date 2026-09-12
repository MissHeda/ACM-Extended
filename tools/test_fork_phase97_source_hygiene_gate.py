#!/usr/bin/env python3
"""Phase 97: reject common build-junk files from addon source trees."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "addons"
BAD_SUFFIXES = {".bak", ".tmp", ".orig", ".rej", ".rpt", ".log", ".pyc", ".pyo", ".zip", ".7z"}
BAD_NAMES = {"thumbs.db", ".ds_store", "desktop.ini"}
BAD_DIRS = {"__pycache__", ".git", ".svn"}


def main() -> None:
    bad: list[str] = []
    for p in ADDONS.rglob("*"):
        rel = p.relative_to(ROOT)
        if p.is_dir():
            if p.name.lower() in BAD_DIRS:
                bad.append(str(rel) + "/")
            continue
        if p.suffix.lower() in BAD_SUFFIXES or p.name.lower() in BAD_NAMES:
            bad.append(str(rel))
    assert not bad, "build-junk files under addons:\n" + "\n".join(bad[:100])
    print("fork phase 97 source-hygiene gate: PASS")


if __name__ == "__main__":
    main()
