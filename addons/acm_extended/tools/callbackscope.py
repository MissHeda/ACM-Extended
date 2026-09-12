#!/usr/bin/env python3
"""Find unsafe _player use in ACE medical treatment action callback fields.

ACE medical treatment callback code exposes the treating provider as _medic. It
also exposes _patient and _bodyPart. It does not define _player. A treatment
callback that reads _player can stop before its requested function runs.

This check only scans ace_medical_treatment_actions. It does not scan ACE self
interaction conditions, where _player is a valid variable.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re

from source_scan import lex, matching

FIELDS = {
    "condition",
    "callbackstart",
    "callbackprogress",
    "callbacksuccess",
    "callbackfailure",
}
PLAYER = re.compile(r"(?<![A-Za-z0-9_])_player(?![A-Za-z0-9_])", re.I)


def run(path: Path) -> list[tuple[int, str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    tokens = lex(text)
    pairs = matching(tokens)

    start = end = None
    for i in range(len(tokens) - 2):
        if (
            tokens[i].kind == "ident"
            and tokens[i].value.lower() == "class"
            and tokens[i + 1].kind == "ident"
            and tokens[i + 1].value.lower() == "ace_medical_treatment_actions"
        ):
            j = i + 2
            while j < len(tokens) and tokens[j].value not in {"{", ";"}:
                j += 1
            if j < len(tokens) and tokens[j].value == "{" and j in pairs:
                start, end = j + 1, pairs[j]
                break
    if start is None or end is None:
        raise ValueError("ace_medical_treatment_actions was not found in config.cpp")

    bad = []
    for i in range(start, end - 2):
        if (
            tokens[i].kind == "ident"
            and tokens[i].value.lower() in FIELDS
            and tokens[i + 1].value == "="
            and tokens[i + 2].kind == "string"
        ):
            body = tokens[i + 2].value
            if PLAYER.search(body):
                bad.append((tokens[i].line, tokens[i].value, body))
    return bad


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", nargs="?", type=Path, default=Path("config.cpp"))
    args = parser.parse_args()
    try:
        bad = run(args.config)
    except (OSError, UnicodeError, ValueError) as exc:
        parser.error(str(exc))
    print(f"Unsafe _player medical treatment references: {len(bad)}")
    for line, field, body in bad:
        print(f"  {args.config}:{line} {field}: {body}")
    return int(bool(bad))


if __name__ == "__main__":
    raise SystemExit(main())
