#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib.util
from datetime import datetime, timezone
from pathlib import Path
import re
import socket


def env_value(text: str, key: str) -> str | None:
    match = re.search(rf"^{re.escape(key)}=(.+)$", text, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None


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


def port_available(port: int, bind_address: str) -> bool:
    checks = []
    if ":" in bind_address:
        checks.extend(
            [
                (socket.AF_INET6, socket.SOCK_STREAM, bind_address),
                (socket.AF_INET6, socket.SOCK_DGRAM, bind_address),
            ]
        )
    else:
        checks.extend(
            [
                (socket.AF_INET, socket.SOCK_STREAM, bind_address),
                (socket.AF_INET, socket.SOCK_DGRAM, bind_address),
            ]
        )

    return all(can_bind(host, port, family, sock_type) for family, sock_type, host in checks)


def choose_port(start: int, end: int, bind_address: str, occupied: set[int]) -> int:
    for port in range(start, end + 1):
        if port in occupied:
            continue
        if port_available(port, bind_address):
            return port
    raise SystemExit(f"no available port found in range {start}-{end}")


def validate_explicit_port(port: int) -> None:
    if port < 1024:
        raise SystemExit(f"refusing privileged port {port}; choose a non-privileged port >= 1024")
    if port > 65535:
        raise SystemExit(f"invalid port {port}; expected 1-65535")


def registry_path_for(env_file: Path) -> Path:
    return env_file.resolve().parents[2] / "registry" / "ports.yaml"


def update_registry(path: Path, *, key: str, port: int, bind_address: str, source: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "ports": [
            {
                "name": key,
                "port": port,
                "bind_address": bind_address,
                "source": source,
            }
        ],
    }
    path.write_text(
        "generated_at: {generated_at}\nports:\n  - name: {name}\n    port: {port}\n    bind_address: {bind_address}\n    source: {source}\n".format(
            generated_at=payload["generated_at"],
            name=payload["ports"][0]["name"],
            port=payload["ports"][0]["port"],
            bind_address=payload["ports"][0]["bind_address"],
            source=payload["ports"][0]["source"],
        )
    )


def write_key(path: Path, key: str, value: str) -> None:
    text = path.read_text() if path.exists() else ""
    if re.search(rf"^{re.escape(key)}=", text, re.MULTILINE):
        text = re.sub(rf"^{re.escape(key)}=.*$", f"{key}={value}", text, flags=re.MULTILINE)
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += f"{key}={value}\n"
    path.write_text(text)
    path.chmod(0o600)


def load_registry_lib(repo_root: Path):
    path = repo_root / "tools" / "port_registry_lib.py"
    if not path.exists():
        raise SystemExit(f"missing tools/port_registry_lib.py under {repo_root}")
    spec = importlib.util.spec_from_file_location("port_registry_lib", path)
    if spec is None or spec.loader is None:
        raise SystemExit("failed to load port_registry_lib")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def bind_host_for_exposure(gov: dict, exposure: str) -> str:
    default_h = str(gov.get("global_default_bind_host", "127.0.0.1") or "127.0.0.1")
    if exposure in ("lan_service", "public_service"):
        return "0.0.0.0"  # aiast-network-bind-lan-public: opt-in governed exposure only
    return default_h


def run_governed_allocate(
    repo_root: Path,
    *,
    project: str,
    service: str,
    service_class: str,
    container_port: int,
    exposure: str,
) -> None:
    if container_port < 1 or container_port > 65535:
        raise SystemExit("container_port must be between 1 and 65535")
    lib = load_registry_lib(repo_root)
    gov_path = repo_root / "registry" / "port_governance.yaml"
    gov = lib.parse_flat_governance(gov_path)
    assign_path = repo_root / "registry" / "port_assignments.yaml"
    entries: list[dict] = [
        e for e in lib.parse_assignments_list(assign_path)
        if not (str(e.get("project")) == project and str(e.get("service")) == service)
    ]
    occupied = lib.compute_occupied_ports(repo_root, gov, entries)
    start, end = lib.range_for_class(gov, service_class)
    bind_host = bind_host_for_exposure(gov, exposure)
    host_port = choose_port(start, end, bind_host, occupied)
    row = {
        "project": project,
        "service": service,
        "host_port": host_port,
        "container_port": container_port,
        "bind_host": bind_host,
        "exposure": exposure,
        "service_class": service_class,
    }
    entries.append(row)
    lib.write_assignments_list(assign_path, entries)
    print(f"ALLOCATED: {bind_host}:{host_port} -> {container_port} (exposure: {exposure})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Allocate host ports for env keys or governed services")
    parser.add_argument(
        "env_file",
        nargs="?",
        default=None,
        help="Path to .env file (legacy mode)",
    )
    parser.add_argument("--key", default="APP_PORT")
    parser.add_argument("--bind-address", default="127.0.0.1")
    parser.add_argument("--start", type=int, default=8000)
    parser.add_argument("--end", type=int, default=9000)
    parser.add_argument("--port", type=int)
    parser.add_argument("--root", default=".", help="Repo root for governed mode")
    parser.add_argument("--project", help="Project id (governed mode)")
    parser.add_argument("--service", help="Service name (governed mode)")
    parser.add_argument(
        "--class",
        dest="service_class",
        choices=["frontend", "backend", "admin", "memory", "ephemeral_dev_pool"],
        help="Port range class (governed mode)",
    )
    parser.add_argument("--container-port", type=int, help="Container internal port (governed mode)")
    parser.add_argument(
        "--exposure",
        default="internal_only",
        choices=["internal_only", "local_ui", "proxied", "lan_service", "public_service"],
    )

    args = parser.parse_args()

    if args.project:
        if not args.service or not args.service_class or args.container_port is None:
            parser.error("governed mode requires --project, --service, --class, and --container-port")
        if args.env_file:
            parser.error("do not pass env_file when using governed mode")
        repo_root = Path(args.root).resolve()
        run_governed_allocate(
            repo_root,
            project=args.project,
            service=args.service,
            service_class=args.service_class,
            container_port=args.container_port,
            exposure=args.exposure,
        )
        return

    if not args.env_file:
        parser.error("legacy mode requires env_file path, or use governed flags (--project ...)")

    path = Path(args.env_file)
    path.parent.mkdir(parents=True, exist_ok=True)
    text = path.read_text() if path.exists() else ""
    current = env_value(text, args.key)

    if args.port is not None:
        validate_explicit_port(args.port)
        port = args.port
    elif current and current.isdigit() and port_available(int(current), args.bind_address):
        port = int(current)
    else:
        occupied: set[int] = set()
        repo_root = path.resolve().parents[2]
        gov_file = repo_root / "registry" / "port_governance.yaml"
        tools_lib = repo_root / "tools" / "port_registry_lib.py"
        if gov_file.is_file() and tools_lib.is_file():
            lib = load_registry_lib(repo_root)
            gov = lib.parse_flat_governance(gov_file)
            assign_path = repo_root / "registry" / "port_assignments.yaml"
            entries = lib.parse_assignments_list(assign_path)
            occupied = lib.compute_occupied_ports(repo_root, gov, entries)
        port = choose_port(args.start, args.end, args.bind_address, occupied)

    write_key(path, args.key, str(port))
    update_registry(
        registry_path_for(path),
        key=args.key,
        port=port,
        bind_address=args.bind_address,
        source=str(path.relative_to(path.resolve().parents[2])),
    )
    print(port)


if __name__ == "__main__":
    main()
