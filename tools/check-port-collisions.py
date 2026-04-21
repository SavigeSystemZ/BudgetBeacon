#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

from port_registry_lib import collect_bindings


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    seen: dict[tuple[str, int], list[str]] = {}
    for bind, port, label in collect_bindings(root):
        if port <= 0:
            continue
        seen.setdefault((bind, port), []).append(label)

    collisions = [(key, labels) for key, labels in seen.items() if len(labels) > 1]
    if collisions:
        for (bind, port), labels in collisions:
            print(f"port collision on {bind}:{port} -> {', '.join(labels)}", file=sys.stderr)
        return 1

    print("port_registry_ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
