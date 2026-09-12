#!/usr/bin/env python3
"""Phase 96: ensure dynamic local asset path templates map to packaged asset families."""
from __future__ import annotations
from pathlib import Path
import glob
import re

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXT = {".cpp", ".hpp", ".sqf", ".inc", ".h"}
DYNAMIC_RE = re.compile(r"%[1-9]")


def strip_comments_keep_strings(text: str) -> str:
    out: list[str] = []
    i = 0
    state = "code"
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
            out.append(c)
            if c == '"':
                if n == '"':
                    out.append(n)
                    i += 1
                else:
                    state = "code"
        else:
            if c == "/" and n == "/":
                out.extend("  ")
                state = "line"
                i += 1
            elif c == "/" and n == "*":
                out.extend("  ")
                state = "block"
                i += 1
            else:
                out.append(c)
                if c == '"':
                    state = "string"
        i += 1
    return "".join(out)


def local_template(value: str) -> Path | None:
    low = value.lower()
    if low.startswith("\\x\\acm\\addons\\"):
        parts = value.split("\\")
        if len(parts) >= 6:
            return ROOT / "addons" / parts[4] / Path("/".join(parts[5:]))
    elif low.startswith("\\acm_extended\\"):
        tail = value[len("\\acm_extended\\"):].replace("\\", "/")
        return ROOT / "addons" / "acm_extended" / Path(tail)
    return None


def main() -> None:
    string_re = re.compile(r'"((?:[^"]|"")*)"')
    occurrences = 0
    families: dict[str, int] = {}
    failures: list[str] = []

    for path in sorted(ROOT.glob("addons/**/*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        text = strip_comments_keep_strings(path.read_text(encoding="utf-8", errors="replace"))
        for line_no, line in enumerate(text.splitlines(), 1):
            for match in string_re.finditer(line):
                value = match.group(1).replace('""', '"')
                if not DYNAMIC_RE.search(value):
                    continue
                target = local_template(value)
                if target is None:
                    continue
                occurrences += 1
                pattern = DYNAMIC_RE.sub("*", str(target))
                matches = glob.glob(pattern)
                families[value] = max(families.get(value, 0), len(matches))
                if not matches:
                    failures.append(
                        f"{path.relative_to(ROOT)}:{line_no}: {value} -> {Path(pattern).relative_to(ROOT)}"
                    )

    assert not failures, "dynamic local asset templates with no packaged matches:\n" + "\n".join(failures[:50])
    assert occurrences >= 20, f"unexpectedly low dynamic reference count: {occurrences}"
    assert len(families) >= 15, f"unexpectedly low dynamic family count: {len(families)}"
    print(
        f"fork phase 96 dynamic asset-family gate: PASS "
        f"({occurrences} refs, {len(families)} templates)"
    )


if __name__ == "__main__":
    main()
