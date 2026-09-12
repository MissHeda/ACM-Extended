#!/usr/bin/env python3
"""Phase 102: every ACME_fnc_* reference must resolve to a registered Extended function."""
from __future__ import annotations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "addons/acm_extended/config.cpp"
TEXT_EXT = {".sqf", ".cpp", ".hpp", ".inc"}


def class_block(text: str, marker: str) -> str:
    start = text.find(marker)
    assert start >= 0, marker
    brace = text.find("{", start)
    assert brace >= 0, marker
    depth = 0
    i = brace
    state = "code"
    quote = ""
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ""
        if state == "line":
            if c == "\n": state = "code"
        elif state == "block":
            if c == "*" and n == "/": state = "code"; i += 1
        elif state == "string":
            if c == quote:
                if n == quote: i += 1
                else: state = "code"
        else:
            if c == "/" and n == "/": state = "line"; i += 1
            elif c == "/" and n == "*": state = "block"; i += 1
            elif c in ('"', "'"): state = "string"; quote = c
            elif c == "{": depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return text[brace + 1:i]
        i += 1
    raise AssertionError(f"unterminated {marker}")


def strip_comments_keep_strings(text: str) -> str:
    out: list[str] = []
    i = 0
    state = "code"
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ""
        if state == "line":
            if c == "\n": state = "code"; out.append("\n")
            else: out.append(" ")
        elif state == "block":
            if c == "*" and n == "/": state = "code"; out.extend("  "); i += 1
            else: out.append("\n" if c == "\n" else " ")
        elif state == "string":
            out.append(c)
            if c == '"':
                if n == '"': out.append(n); i += 1
                else: state = "code"
        else:
            if c == "/" and n == "/": state = "line"; out.extend("  "); i += 1
            elif c == "/" and n == "*": state = "block"; out.extend("  "); i += 1
            else:
                out.append(c)
                if c == '"': state = "string"
        i += 1
    return "".join(out)


def main() -> None:
    cfg = CFG.read_text(encoding="utf-8", errors="replace")
    area = class_block(class_block(class_block(cfg, "class CfgFunctions"), "class ACME"), "class infusion")
    names = re.findall(r"\bclass\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{\s*\}\s*;", area)
    registered = {f"acme_fnc_{name}".casefold() for name in names}
    assert len(registered) == len(names), "duplicate ACME CfgFunctions registration names"

    refs: dict[str, list[str]] = {}
    symbol_re = re.compile(r"\bACME_fnc_[A-Za-z0-9_]+\b", re.I)
    for path in sorted(ROOT.glob("addons/**/*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        text = strip_comments_keep_strings(path.read_text(encoding="utf-8", errors="replace"))
        for match in symbol_re.finditer(text):
            raw = match.group(0)
            refs.setdefault(raw.casefold(), []).append(str(path.relative_to(ROOT)))

    unresolved = sorted(set(refs) - registered)
    assert not unresolved, "unresolved ACME function symbols:\n" + "\n".join(
        f"{sym}: {refs[sym][:4]}" for sym in unresolved[:100]
    )
    assert len(refs) > 900, f"unexpectedly low ACME symbol reference set: {len(refs)}"
    print(f"fork phase 102 ACME function-symbol closure: PASS ({len(registered)} registered, {len(refs)} referenced symbols)")


if __name__ == "__main__":
    main()
