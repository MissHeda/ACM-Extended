"""find a member defined twice in the same class body.

the engine rejects the whole file for this, with "Member already defined", and it is easy to introduce by
inserting a property into a class that already declares it further down.
this walks the class tree and compares members at their own depth only, so a member of a nested class does not
count against its parent.
"""

import re
import sys


def strip(src):
    """blank strings and comments, keeping offsets."""
    out = list(src)
    i = 0
    n = len(src)
    st = None
    while i < n:
        c = src[i]
        nx = src[i + 1] if i + 1 < n else ""
        if st is None:
            if c == '"':
                st = '"'
                out[i] = " "
            elif c == "/" and nx == "/":
                st = "//"
                out[i] = out[i + 1] = " "
                i += 1
            elif c == "/" and nx == "*":
                st = "/*"
                out[i] = out[i + 1] = " "
                i += 1
        elif st == '"':
            out[i] = " "
            if c == '"':
                st = None
        elif st == "//":
            if c == "\n":
                st = None
            else:
                out[i] = " "
        elif st == "/*":
            if c == "*" and nx == "/":
                out[i] = out[i + 1] = " "
                i += 1
                st = None
            elif c != "\n":
                out[i] = " "
        i += 1
    return "".join(out)


def check(path):
    raw = open(path, encoding="cp1252", errors="replace").read()
    code = strip(raw)
    errs = []

    # walk every class body and collect the members declared directly inside it
    for m in re.finditer(r'\bclass\s+([A-Za-z0-9_]+)\s*(?::\s*[A-Za-z0-9_]+\s*)?\{', code):
        name = m.group(1)
        start = m.end()
        depth = 1
        i = start
        while depth and i < len(code):
            if code[i] == "{":
                depth += 1
            elif code[i] == "}":
                depth -= 1
            i += 1
        body = code[start:i - 1]

        # remove nested class bodies so their members are not counted here
        flat = []
        d = 0
        for ch in body:
            if ch == "{":
                d += 1
            elif ch == "}":
                d -= 1
            flat.append(ch if d == 0 else " ")
        flat = "".join(flat)

        seen = {}
        for mm in re.finditer(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*(?:\[\s*\])?\s*=', flat):
            key = mm.group(1)
            ln = code[:start + mm.start()].count("\n") + 1
            if key in seen:
                errs.append("%s:%d class %s member %s already defined at line %d"
                            % (path, ln, name, key, seen[key]))
            else:
                seen[key] = ln
    return errs


if __name__ == "__main__":
    # the default is RELATIVE. it used to be an absolute path into a working tree that no longer exists,
    # so running the tool with no argument crashed with FileNotFoundError instead of checking anything.
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
