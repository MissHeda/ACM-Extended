#!/usr/bin/env python3
"""Small, non-executing SQF/config lexer shared by source checks.

This is not an SQF parser, compiler, preprocessor, or a runtime reachability proof.
Offsets and line numbers are retained. Quoted config callbacks are scanned as code;
ordinary text strings and comments are not treated as executable function references.
"""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterator

@dataclass(frozen=True)
class Token:
    kind: str
    value: str
    line: int
    offset: int

_IDENT = re.compile(r'[A-Za-z_][A-Za-z_0-9]*')
_NUMBER = re.compile(r'(?:0[xX][0-9A-Fa-f]+|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)')
CODE_FIELDS = {
    'action', 'condition', 'expression', 'statement', 'statementstart', 'statementprogress',
    'statementend', 'callback', 'callbacksuccess', 'callbackfailure', 'callbackstart',
    'callbackprogress', 'callbackend', 'init', 'attributeLoad'.lower(), 'attributeSave'.lower(),
}

def lex(text: str, start_line: int = 1) -> list[Token]:
    out: list[Token] = []
    i = 0
    line = start_line
    while i < len(text):
        c = text[i]
        if c.isspace():
            line += c == '\n'; i += 1; continue
        if text.startswith('//', i):
            j = text.find('\n', i + 2); i = len(text) if j < 0 else j; continue
        if text.startswith('/*', i):
            j = text.find('*/', i + 2); j = len(text) if j < 0 else j + 2
            line += text[i:j].count('\n'); i = j; continue
        if c in '\"\'':
            start, ln, quote = i, line, c
            i += 1; value = []
            while i < len(text):
                if text[i] == quote:
                    if i + 1 < len(text) and text[i+1] == quote:
                        value.append(quote); i += 2; continue
                    i += 1; break
                line += text[i] == '\n'; value.append(text[i]); i += 1
            out.append(Token('string', ''.join(value), ln, start)); continue
        m = _IDENT.match(text, i)
        if m:
            out.append(Token('ident', m[0], line, i)); i = m.end(); continue
        m = _NUMBER.match(text, i)
        if m:
            out.append(Token('number', m[0], line, i)); i = m.end(); continue
        pair = text[i:i+2]
        if pair in {'==','!=','<=','>=','&&','||','>>','<<','+=','-=','##'}:
            out.append(Token('symbol',pair,line,i)); i += 2
        else:
            out.append(Token('symbol',c,line,i)); i += 1
    return out

def code_streams(text: str, config: bool = False, start_line: int = 1) -> Iterator[list[Token]]:
    tokens = lex(text, start_line)
    yield tokens
    pairs = matching(tokens)
    callbacks: set[int] = set()
    # Event handler code is the second array argument, sometimes a format string.
    # Do not treat text passed to hints, labels or diagnostic logs as executable.
    for i, tok in enumerate(tokens):
        if tok.value.lower() not in {'ctrladdeventhandler','displayaddeventhandler','addeventhandler',
                                     'ctrlseteventhandler','displayseteventhandler'}:
            continue
        if i+1 >= len(tokens) or tokens[i+1].value != '[' or i+1 not in pairs:
            continue
        args = split_args(tokens, i+2, pairs[i+1], pairs)
        if len(args) < 2: continue
        arg = args[1]
        if len(arg) == 1 and arg[0].kind == 'string': callbacks.add(arg[0].offset)
        elif len(arg) >= 3 and arg[0].value.lower() == 'format' and arg[1].value == '[' and arg[2].kind == 'string':
            callbacks.add(arg[2].offset)
    for i, tok in enumerate(tokens):
        if tok.kind != 'string': continue
        executable = tok.offset in callbacks
        if config and i >= 2 and tokens[i-1].value == '=':
            key = tokens[i-2].value.lower()
            executable |= key.startswith('on') or key in CODE_FIELDS
        if i >= 1 and tokens[i-1].value.lower() in {'compile','compilefinal'}:
            executable = True
        if executable:
            yield from code_streams(tok.value, False, tok.line)

def source_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in {'.sqf','.hpp','.cpp','.inc'}
                  and not any(x in {'__pycache__','.git','node_modules'} for x in p.parts))

def matching(tokens: list[Token]) -> dict[int,int]:
    pairs: dict[int,int] = {}; stack: list[int] = []
    end = {']':'[','}':'{',')':'('}
    for i,t in enumerate(tokens):
        if t.kind != 'symbol': continue
        if t.value in {'[','{','('}: stack.append(i)
        elif t.value in end and stack and tokens[stack[-1]].value == end[t.value]:
            j=stack.pop(); pairs[j]=i; pairs[i]=j
    return pairs

def split_args(tokens: list[Token], begin: int, end: int, pairs: dict[int,int]) -> list[list[Token]]:
    result: list[list[Token]] = []; mark=begin; i=begin
    while i < end:
        if tokens[i].value in {'[','{','('} and i in pairs:
            i=pairs[i]+1; continue
        if tokens[i].value == ',':
            result.append(tokens[mark:i]); mark=i+1
        i+=1
    if mark<end: result.append(tokens[mark:end])
    return result

def render(tokens: list[Token]) -> str:
    return ' '.join(('"'+t.value+'"') if t.kind=='string' else t.value for t in tokens)

def addons_root(root: Path) -> Path:
    if root.name.lower() == 'addons': return root
    if (root/'addons').is_dir(): return root/'addons'
    found = sorted(p for p in root.glob('*/addons') if p.is_dir())
    if len(found)==1: return found[0]
    raise ValueError(f'Cannot identify a unique addons directory under {root}')
