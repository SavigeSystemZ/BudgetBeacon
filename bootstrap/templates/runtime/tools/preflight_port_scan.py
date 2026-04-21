#!/usr/bin/env python3
from __future__ import annotations

import socket
import sys
from pathlib import Path

from port_registry_lib import collect_bindings


def can_bind(host: str, port: int, family: socket.AddressFamily, sock_type: socket.SocketKind) -> bool:
    try:
        sock = socket.socket(family, sock_type)
        if family == socket.AF_INET6:
            sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        sock.bind((host, port))
        sock.close()
        return True
    except OSError:
        return False


def binding_available(host: str, port: int) -> bool:
    if ":" in host:
        checks = [
            (socket.AF_INET6, socket.SOCK_STREAM),
            (socket.AF_INET6, socket.SOCK_DGRAM),
        ]
    else:
        checks = [
            (socket.AF_INET, socket.SOCK_STREAM),
            (socket.AF_INET, socket.SOCK_DGRAM),
        ]
    return all(can_bind(host, port, family, sock_type) for family, sock_type in checks)


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    failures: list[str] = []
    for bind, port, label in collect_bindings(root):
        if port <= 0:
            continue
        if not binding_available(bind, port):
            failures.append(f"{bind}:{port} unavailable for {label}")

    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1

    print("port_preflight_ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
