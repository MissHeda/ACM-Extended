"""brace, bracket and paren balance for sqf, string and comment aware.
also flags trailing commas, selected missing separators, and banned dash/arrow characters.
This is a structural screen. It does not compile SQF or establish runtime correctness.
"""

import glob
import os
import re
import sys
from pathlib import Path

BANNED = {
    "\u2014": "em dash",
    "\u2013": "en dash",
    "\u2192": "right arrow",
    "\u2190": "left arrow",
    "\u21d2": "double arrow",
    "&mdash;": "em dash entity",
    "&ndash;": "en dash entity",
    "&rarr;": "arrow entity",
    "&#8212;": "em dash entity",
    "&#8211;": "en dash entity",
}


def strip_code(src):
    """blank out strings and comments, keeping length and newlines."""
    out = list(src)
    i = 0
    n = len(src)
    state = None
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if state is None:
            if c == '"':
                state = '"'
                out[i] = "S"
            elif c == "'":
                state = "'"
                out[i] = "S"
            elif c == "/" and nxt == "/":
                state = "//"
                out[i] = out[i + 1] = " "
                i += 1
            elif c == "/" and nxt == "*":
                state = "/*"
                out[i] = out[i + 1] = " "
                i += 1
        elif state in ('"', "'"):
            out[i] = "S"
            if c == state:
                if nxt == state:  # doubled quote is an escaped quote in sqf
                    out[i + 1] = "S"
                    i += 1
                else:
                    state = None
        elif state == "//":
            if c == "\n":
                state = None
            else:
                out[i] = " "
        elif state == "/*":
            if c == "*" and nxt == "/":
                out[i] = out[i + 1] = " "
                i += 1
                state = None
            else:
                out[i] = " " if c != "\n" else "\n"
        i += 1
    return "".join(out)


def check(path):
    try:
        raw = Path(path).read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        return [f"{path}: cannot read UTF-8 source: {exc}"]
    errs = []
    for bad, name in BANNED.items():
        if bad in raw:
            ln = raw[:raw.index(bad)].count("\n") + 1
            errs.append("%s:%d banned %s" % (path, ln, name))
    code = strip_code(raw)
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for idx, ch in enumerate(code):
        if ch in "([{":
            stack.append((ch, idx))
        elif ch in ")]}":
            if not stack:
                errs.append("%s:%d unmatched %s" % (path, code[:idx].count("\n") + 1, ch))
                break
            op, oi = stack.pop()
            if op != pairs[ch]:
                errs.append("%s:%d %s closed by %s" % (path, code[:idx].count("\n") + 1, op, ch))
                break
    if stack:
        op, oi = stack[-1]
        errs.append("%s:%d unclosed %s" % (path, code[:oi].count("\n") + 1, op))
    for m in re.finditer(r",\s*[\]\}\)]", code):
        errs.append("%s:%d trailing comma" % (path, code[:m.start()].count("\n") + 1))

    # a bare return value with code after it. sqf needs a semicolon between statements, and a lone true or
    # false followed by another statement kills the whole file at compile with "missing ;".
    lines = code.split("\n")
    for i, ln in enumerate(lines):
        t = ln.strip()
        if t not in ("true", "false"):
            continue
        for j in range(i + 1, len(lines)):
            nxt = lines[j].strip()
            if nxt == "":
                continue
            if nxt.startswith("}") or nxt.startswith("]") or nxt.startswith(")"):
                break
            errs.append("%s:%d bare '%s' with a statement after it, missing ;" % (path, i + 1, t))
            break
    return errs


if __name__ == "__main__":
    roots = sys.argv[1:] or [str(Path(__file__).resolve().parents[1])]
    files = []
    for r in roots:
        if os.path.isdir(r):
            files += sorted(glob.glob(os.path.join(r, "**", "*.sqf"), recursive=True))
        else:
            files.append(r)
    allerr = []
    for f in files:
        allerr += check(f)
    print("checked %d files" % len(files))
    if allerr:
        for e in allerr:
            print("  " + e)
        print("FAIL %d" % len(allerr))
        sys.exit(1)
    print("clean")
