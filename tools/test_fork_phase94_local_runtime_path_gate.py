#!/usr/bin/env python3
"""Phase 94: validate exact project-local rooted runtime/source paths with case-sensitive lookup."""
from __future__ import annotations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXT = {".cpp", ".hpp", ".sqf", ".inc", ".h"}
FILE_EXT = {
    ".sqf", ".hpp", ".inc", ".paa", ".pac", ".p3d", ".ogg", ".wav", ".wss", ".fxy",
    ".rtm", ".rvmat", ".jpg", ".jpeg", ".png", ".html", ".xml", ".fsm",
}
DYNAMIC_MARKERS = ("%1", "%2", "%3", "%4", "%5", "%6", "%7", "%8", "%9", "##")


def strip_comments_keep_strings(text: str) -> str:
    """Blank // and /* */ comments while preserving quoted strings and line positions."""
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
    assert state != "block", "unterminated block comment"
    return "".join(out)


def local_target(value: str) -> Path | None:
    low = value.lower()
    if low.startswith("\\x\\acm\\addons\\"):
        parts = value.split("\\")
        if len(parts) < 6:
            return None
        return ROOT / "addons" / parts[4] / Path("/".join(parts[5:]))
    if low.startswith("\\acm_extended\\"):
        tail = value[len("\\acm_extended\\"):].replace("\\", "/")
        return ROOT / "addons" / "acm_extended" / Path(tail)
    return None


def main() -> None:
    exact = 0
    guarded_optional = 0
    failures: list[str] = []
    string_re = re.compile(r'"((?:[^"]|"")*)"')

    for path in sorted(ROOT.glob("addons/**/*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        text = strip_comments_keep_strings(path.read_text(encoding="utf-8", errors="replace"))
        lines = text.splitlines()
        for line_no, line in enumerate(lines, 1):
            for match in string_re.finditer(line):
                value = match.group(1).replace('""', '"')
                target = local_target(value)
                if target is None:
                    continue
                if any(marker in value for marker in DYNAMIC_MARKERS):
                    continue
                if target.suffix.lower() not in FILE_EXT:
                    continue
                exact += 1
                if target.exists():
                    continue
                # fileExists is deliberately used by optional-asset fallbacks. A missing guarded optional file is
                # not a broken runtime reference; all unguarded exact local paths remain fatal.
                if "fileExists" in line:
                    guarded_optional += 1
                    continue
                failures.append(f"{path.relative_to(ROOT)}:{line_no}: {value} -> {target.relative_to(ROOT)}")

    assert not failures, "missing exact project-local rooted paths:\n" + "\n".join(failures[:50])
    assert exact > 100, f"unexpectedly low local reference count: {exact}"
    print(
        f"fork phase 94 local runtime path gate: PASS "
        f"({exact} exact refs, {guarded_optional} guarded optional missing refs)"
    )


if __name__ == "__main__":
    main()
