"""find a class name mentioned more than once in the same config scope.

the engine rejects the whole file with "Member already defined", the same message a duplicate PROPERTY gives,
so tools/dupmember.py does not catch this and the message does not say which of the two it is.

THE RULE, learned the hard way across v0.9.999r-50, r-51 and r-52, all three rejected on one line.

    A CLASS NAME MAY APPEAR ONCE PER SCOPE.

either you forward-declare it, so something below can inherit from it:

    class X;
    class Y: X { ... };

or you reopen it to modify a class that already exists in another addon:

    class X { prop = value; };

DOING BOTH IS TWO MENTIONS OF ONE MEMBER and the file is rejected. so is defining it twice. and a reopen must
carry NO PARENT, because "class X: P { ... }" declares a new class of that name rather than modifying the one
that is already there.

the proven form for modifying an ACM class is in config.cpp already: InsertIV_16_Upper and ApplyChestSeal are
reopened with a body, no parent and no declaration anywhere above them.

this check reported the whole shipped config clean at the time it was written, with the two offending mentions
removed, so the rule is not a guess about the engine. it is measured against every class in the file.

usage: python3 tools/dupclass.py config.cpp
"""

import re
import sys


def strip_noise(text):
    """remove block comments, line comments and string literals, keeping newlines so line numbers hold."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\n":
                    break
                j += 1
            out.append(" " * (j - i + 1))
            i = j + 1
            continue
        if text.startswith("//", i):
            j = text.find("\n", i)
            if j < 0:
                j = n
            out.append(" " * (j - i))
            i = j
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i)
            if j < 0:
                j = n
            seg = text[i:j + 2]
            out.append("".join(ch if ch == "\n" else " " for ch in seg))
            i = j + 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


DECL = re.compile(r"\bclass\s+(\w+)\s*;")
DEFN = re.compile(r"\bclass\s+(\w+)\s*(?::\s*\w+\s*)?\{")


def check(path):
    src = strip_noise(open(path, "rb").read().decode("utf-8", errors="replace"))
    errs = []
    scopes = [{}]          # one name -> first line, per brace depth
    line = 1
    i = 0
    n = len(src)
    while i < n:
        ch = src[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == "{":
            scopes.append({})
            i += 1
            continue
        if ch == "}":
            if len(scopes) > 1:
                scopes.pop()
            i += 1
            continue
        if src.startswith("class", i) and (i == 0 or (not src[i - 1].isalnum() and src[i - 1] != "_")):
            m = DEFN.match(src, i)
            kind = "definition"
            if not m:
                m = DECL.match(src, i)
                kind = "forward declaration"
                step = m.end() if m else None
            else:
                step = m.end() - 1   # stop on the brace so the depth bookkeeping stays right
            if m:
                name = m.group(1)
                if name in scopes[-1]:
                    errs.append("%s:%d: class %s, this %s is a SECOND mention in one scope. "
                                "the first is at line %d. a name may appear once: declare it OR reopen it, "
                                "never both, and a reopen carries no parent."
                                % (path, line, name, kind, scopes[-1][name]))
                else:
                    scopes[-1][name] = line
                i = step
                continue
        i += 1
    return errs


if __name__ == "__main__":
    paths = sys.argv[1:] or ["config.cpp"]
    bad = []
    for p in paths:
        bad += check(p)
    print("checked %d file(s)" % len(paths))
    if bad:
        for b in bad:
            print("  " + b)
        print("FAIL %d" % len(bad))
        sys.exit(1)
    print("clean")
