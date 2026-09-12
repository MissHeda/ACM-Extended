#!/usr/bin/env python3
"""Phase 101: validate the repository-local config/header include graph is acyclic and non-duplicated."""
from __future__ import annotations
from collections import Counter
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "addons"
INC_RE = re.compile(r'^\s*#\s*include\s*["<]([^">]+)[">]', re.M)
EXTERNAL = ("\\a3\\", "\\x\\cba\\", "\\z\\ace\\")


def resolve(src: Path, raw: str) -> Path | None:
    value = raw.replace("/", "\\")
    low = value.lower()
    prefix = "\\x\\acm\\addons\\"
    if low.startswith(prefix):
        return ADDONS.joinpath(*[x for x in value[len(prefix):].split("\\") if x])
    if any(low.startswith(x) for x in EXTERNAL):
        return None
    if value.startswith("\\"):
        return None
    return src.parent.joinpath(*[x for x in value.split("\\") if x])


def main() -> None:
    roots = sorted(ADDONS.glob("*/config.cpp"))
    graph: dict[Path, list[Path]] = {}
    duplicates: list[str] = []
    missing: list[str] = []
    seen: set[Path] = set()

    def walk(path: Path) -> None:
        path = path.resolve()
        if path in seen:
            return
        seen.add(path)
        text = path.read_text(encoding="utf-8", errors="replace")
        includes = INC_RE.findall(text)
        for raw, count in Counter(includes).items():
            if count > 1:
                duplicates.append(f"{path.relative_to(ROOT)}: {raw} x{count}")
        edges: list[Path] = []
        for raw in includes:
            target = resolve(path, raw)
            if target is None:
                continue
            if not target.is_file():
                missing.append(f"{path.relative_to(ROOT)}: {raw} -> {target.relative_to(ROOT)}")
                continue
            target = target.resolve()
            edges.append(target)
            walk(target)
        graph[path] = edges

    for root in roots:
        walk(root)

    assert not missing, "missing local preprocessor includes:\n" + "\n".join(missing[:100])
    assert not duplicates, "duplicate direct preprocessor includes:\n" + "\n".join(duplicates[:100])

    state: dict[Path, int] = {}
    stack: list[Path] = []

    def visit(node: Path) -> None:
        mark = state.get(node, 0)
        if mark == 2:
            return
        if mark == 1:
            i = stack.index(node)
            cycle = stack[i:] + [node]
            raise AssertionError(
                "local preprocessor include cycle: "
                + " -> ".join(str(x.relative_to(ROOT)) for x in cycle)
            )
        state[node] = 1
        stack.append(node)
        for dep in graph.get(node, []):
            visit(dep)
        stack.pop()
        state[node] = 2

    for node in sorted(graph):
        visit(node)

    edge_count = sum(len(v) for v in graph.values())
    print(f"fork phase 101 preprocessor include-graph gate: PASS ({len(graph)} nodes, {edge_count} local edges)")


if __name__ == "__main__":
    main()
