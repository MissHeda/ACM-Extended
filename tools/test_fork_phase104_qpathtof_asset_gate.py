#!/usr/bin/env python3
"""Phase 104: case-exact closure for active addon-local QPATHTOF/PATHTOF file references."""
from __future__ import annotations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXT = {".sqf", ".cpp", ".hpp", ".inc", ".h"}
MACRO_RE = re.compile(r"\b(Q?PATHTOF)\(([^)]+)\)")


def strip_comments_keep_lines(text: str) -> str:
    out=[]; i=0; state='code'; quote=''
    while i < len(text):
        c=text[i]; n=text[i+1] if i+1<len(text) else ''
        if state=='line':
            if c=='\n': state='code'; out.append('\n')
            else: out.append(' ')
        elif state=='block':
            if c=='*' and n=='/': state='code'; out.extend('  '); i+=1
            else: out.append('\n' if c=='\n' else ' ')
        elif state=='string':
            out.append(c)
            if c==quote:
                if n==quote: out.append(n); i+=1
                else: state='code'
        else:
            if c=='/' and n=='/': state='line'; out.extend('  '); i+=1
            elif c=='/' and n=='*': state='block'; out.extend('  '); i+=1
            elif c in ('"',"'"): state='string'; quote=c; out.append(c)
            else: out.append(c)
        i+=1
    return ''.join(out)


def main() -> None:
    checked=0; failures=[]; skipped_dead_defines=0
    for path in sorted(ROOT.glob('addons/**/*')):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        raw=path.read_text(encoding='utf-8',errors='replace')
        text=strip_comments_keep_lines(raw)
        for line_no,line in enumerate(text.splitlines(),1):
            for m in MACRO_RE.finditer(line):
                arg=m.group(2).strip()
                # Macro-generated/dynamic paths are covered by the dynamic-family gate where applicable.
                if any(x in arg for x in ('#','%','(',')')):
                    continue
                addon_root = ROOT / 'addons' / path.relative_to(ROOT / 'addons').parts[0]
                target=addon_root / Path(arg.replace('\\','/'))
                if not target.suffix:
                    continue
                # A path hidden inside an otherwise-unused #define is not dereferenced by the preprocessor.
                if line.lstrip().startswith('#define'):
                    dm=re.match(r'\s*#define\s+([A-Za-z_][A-Za-z0-9_]*)',line)
                    if dm and len(re.findall(r'\b'+re.escape(dm.group(1))+r'\b',raw)) == 1:
                        skipped_dead_defines += 1
                        continue
                checked += 1
                if not target.exists():
                    failures.append(f'{path.relative_to(ROOT)}:{line_no}: {m.group(0)} -> {target.relative_to(ROOT)}')
    assert not failures, 'missing/case-mismatched active QPATHTOF/PATHTOF files:\n'+'\n'.join(failures[:100])
    assert checked > 200, checked
    print(f'fork phase 104 QPATHTOF asset gate: PASS ({checked} exact file refs, {skipped_dead_defines} unused path defines skipped)')

if __name__=='__main__': main()
