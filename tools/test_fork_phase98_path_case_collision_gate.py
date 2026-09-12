#!/usr/bin/env python3
"""Phase 98: reject case-colliding source paths that differ across build/server filesystems."""
from pathlib import Path
import unicodedata

ROOT = Path(__file__).resolve().parents[1]


def key(path: Path) -> str:
    # Windows build hosts are normally case-insensitive. NFC also avoids visually identical Unicode names
    # becoming separate archive members on Linux/macOS.
    return unicodedata.normalize("NFC", path.as_posix()).casefold()


def main() -> None:
    seen: dict[str, str] = {}
    collisions: list[tuple[str, str]] = []
    count = 0
    for p in sorted((ROOT / "addons").rglob("*")):
        if not p.is_file():
            continue
        count += 1
        rel = p.relative_to(ROOT)
        k = key(rel)
        prior = seen.get(k)
        if prior is not None and prior != rel.as_posix():
            collisions.append((prior, rel.as_posix()))
        else:
            seen[k] = rel.as_posix()
    assert not collisions, "case/Unicode-colliding addon paths: " + repr(collisions[:50])
    print(f"fork phase 98 path case-collision gate: PASS ({count} addon files)")


if __name__ == "__main__":
    main()
