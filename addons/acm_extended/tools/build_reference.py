"""build a distilled ACM and ACE reference from the real sources.

nothing in the output is typed by hand. every name, signature and constant is read out of the source
files, so the sheet cannot drift from what the code actually does.

run it with the two sources extracted under /home/claude/src, and it writes the sheet into the addon
tree so it travels with every upload of the mod.
"""

import os
import re
import sys

ACM = "/home/claude/src/ACM-main/ACM-main"
ACE = "/home/claude/src/ACE3-master"
OUT = "/home/claude/work4/acm_extended/ACM_ACE_REFERENCE.md"


def read(path):
    try:
        return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""


def walk(root, ext):
    for base, _, files in os.walk(root):
        for f in files:
            if f.endswith(ext):
                yield os.path.join(base, f)


def component_of(path, root):
    """the addons/<component>/ this file belongs to, which is the CfgFunctions tag."""
    rel = os.path.relpath(path, root)
    parts = rel.split(os.sep)
    if "addons" in parts:
        i = parts.index("addons")
        if i + 1 < len(parts):
            return parts[i + 1]
    return "?"


def params_of(src):
    """the first params line of a function, which is its call signature."""
    m = re.search(r'^\s*params\s*(\[[^;]*\])\s*;', src, re.M)
    if not m:
        return ""
    return re.sub(r'\s+', ' ', m.group(1)).strip()


def collect_functions(root, prefix):
    """every fnc_*.sqf, with its component tag, resolved name and signature."""
    out = []
    for p in walk(root, ".sqf"):
        name = os.path.basename(p)
        if not name.startswith("fnc_"):
            continue
        comp = component_of(p, root)
        fn = name[4:-4]
        src = read(p)
        out.append((comp, fn, params_of(src), p))
    return out


def resolve_tag(comp, kind):
    """the real CfgFunctions tag for a component. this is the thing that has bitten us."""
    if kind == "ACM":
        # ACM's main component is ACM_core, gui is ACM_GUI, the rest are ACM_<component>.
        if comp == "core":
            return "ACM_core"
        if comp == "gui":
            return "ACM_GUI"
        if comp == "main":
            return "ACM_main"
        return "ACM_" + comp
    return "ace_" + comp


def macro_defines(root, names):
    """resolve the given macro names from every script_macros header."""
    found = {}
    for p in walk(root, ".hpp"):
        if "script_macros" not in os.path.basename(p):
            continue
        src = read(p)
        for n in names:
            m = re.search(r'^\s*#define\s+%s\b(.*)$' % re.escape(n), src, re.M)
            if m and n not in found:
                found[n] = (m.group(1).strip(), os.path.relpath(p, root))
    return found


def main():
    lines = []
    add = lines.append

    add("# ACM and ACE reference")
    add("")
    add("Generated from the ACM and ACE sources by tools/build_reference.py. Nothing here is written by")
    add("hand. Regenerate it whenever either source is updated.")
    add("")
    add("It lives in the addon tree on purpose, so it arrives with every upload of the mod and the exact")
    add("names, signatures and constants are available without the full sources present.")
    add("")
    add("***")
    add("")

    # the component tags, which is the failure that keeps recurring
    add("## Component tags")
    add("")
    add("A CfgFunctions override must be filed under the tag of the component the function lives in. Filed")
    add("under the wrong tag it compiles under the wrong name and the original keeps running, silently.")
    add("")
    add("| Component | Tag | Functions |")
    add("|---|---|---|")
    acm_fns = collect_functions(ACM, "ACM")
    ace_fns = collect_functions(ACE, "ace")
    counts = {}
    for comp, fn, sig, p in acm_fns:
        counts.setdefault(("ACM", comp), 0)
        counts[("ACM", comp)] += 1
    for (kind, comp), n in sorted(counts.items()):
        add("| ACM %s | `%s` | %d |" % (comp, resolve_tag(comp, "ACM"), n))
    add("")

    # macros we actually rely on
    add("## Macros and constants")
    add("")
    want_ace = ["GET_BLOOD_VOLUME", "DEFAULT_BLOOD_VOLUME", "GET_HEART_RATE", "GET_FRACTURES",
                "DEFAULT_FRACTURE_VALUES", "VAR_BLOOD_VOL", "VAR_HEART_RATE", "VAR_FRACTURES",
                "VAR_PERIPH_RES", "DEFAULT_PERIPH_RES", "GET_PAIN", "IS_UNCONSCIOUS",
                "VENTRICLE_STROKE_VOL", "DEFAULT_HEART_RATE"]
    want_acm = ["GET_OXYGEN", "VAR_SPO2", "GET_IV", "GET_IO", "ALL_BODY_PARTS",
                "GET_BODYPART_INDEX", "IN_CRDC_ARRST", "LYING_ANIMATION"]
    for kind, root, want in (("ACE", ACE, want_ace), ("ACM", ACM, want_acm)):
        found = macro_defines(root, want)
        if not found:
            continue
        add("### %s" % kind)
        add("")
        add("| Macro | Definition | Header |")
        add("|---|---|---|")
        for n in want:
            if n in found:
                val, where = found[n]
                val = val.replace("|", "\\|")
                add("| `%s` | `%s` | %s |" % (n, val[:110], where))
        add("")

    # the functions this addon actually calls, with their real signatures
    add("## Signatures of everything this addon calls")
    add("")
    add("Read out of the source. A wrong argument order here fails silently rather than erroring.")
    add("")
    tree = "/home/claude/work4/acm_extended"
    used = set()
    # comments and isNil guards are stripped first. a name mentioned in a comment explaining that it does
    # not exist, or read behind a guard as a deliberate fallback, is not a call and must not be reported as a
    # missing one. without this the sheet reports five false alarms that are all correctly handled already.
    for p in list(walk(tree, ".sqf")) + [os.path.join(tree, "config.cpp")]:
        src = read(p)
        src = re.sub(r'//[^\n]*', ' ', src)
        src = re.sub(r'isNil\s*"[^"]*"', ' ', src)
        for m in re.findall(r'\b(ACM_[A-Za-z]+_fnc_[A-Za-z0-9_]+|ace_[a-z_]+_fnc_[A-Za-z0-9_]+)\b', src):
            used.add(m)

    # sqf is case insensitive, so the index is keyed lower. without this a call written in a different
    # case than the file name reads as a missing function and hides the ones that really are missing.
    index = {}
    canon = {}
    for comp, fn, sig, p in acm_fns:
        k = "%s_fnc_%s" % (resolve_tag(comp, "ACM"), fn)
        index[k.lower()] = (sig, os.path.relpath(p, ACM))
        canon[k.lower()] = k
    for comp, fn, sig, p in ace_fns:
        k = "%s_fnc_%s" % (resolve_tag(comp, "ace"), fn)
        index[k.lower()] = (sig, os.path.relpath(p, ACE))
        canon[k.lower()] = k

    hit = sorted(n for n in used if n.lower() in index)
    miss = sorted(n for n in used if n.lower() not in index)

    add("| Function | params |")
    add("|---|---|")
    for n in hit:
        sig, where = index[n.lower()]
        sig = (sig or "(none)").replace("|", "\\|")
        real = canon[n.lower()]
        shown = n if n == real else ("%s  (file: %s)" % (n, real))
        add("| `%s` | `%s` |" % (shown, sig[:150]))
    add("")

    if miss:
        add("### Called but not found in either source")
        add("")
        add("These resolve at runtime, are defined by this addon, or do not exist. Anything here that is")
        add("meant to be an ACM or ACE function is a name to check.")
        add("")
        for n in miss:
            add("- `%s`" % n)
        add("")

    add("## Counts")
    add("")
    add("- ACM functions indexed: %d" % len(acm_fns))
    add("- ACE functions indexed: %d" % len(ace_fns))
    add("- Called by this addon and resolved: %d" % len(hit))
    add("- Called by this addon and unresolved: %d" % len(miss))
    add("")

    txt = "\n".join(lines) + "\n"
    for bad in ("\u2014", "\u2013", "\u2192"):
        txt = txt.replace(bad, " ")
    open(OUT, "w", encoding="utf-8").write(txt)
    print("wrote %s, %d lines" % (OUT, txt.count("\n")))
    print("resolved %d of %d called functions" % (len(hit), len(hit) + len(miss)))
    if miss:
        print("unresolved:")
        for n in miss[:20]:
            print("   " + n)


if __name__ == "__main__":
    main()
