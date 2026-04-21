#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from typing import Iterable


def _coerce_scalar(value: str):
    raw = value.strip()
    if raw.lower() == "true":
        return True
    if raw.lower() == "false":
        return False
    if raw.isdigit():
        return int(raw)
    return raw


def parse_flat_governance(path: Path) -> dict:
    if not path.exists():
        return {}
    data: dict[str, object] = {}
    list_key: str | None = None
    for raw_line in path.read_text().splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if line.startswith("  - ") and list_key:
            data.setdefault(list_key, [])
            assert isinstance(data[list_key], list)
            data[list_key].append(_coerce_scalar(stripped[2:].strip()))
            continue
        list_key = None
        if ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            data[key] = []
            list_key = key
        else:
            data[key] = _coerce_scalar(value)
    return data


def _parse_named_entries(path: Path, section: str) -> list[dict]:
    if not path.exists():
        return []
    entries: list[dict] = []
    in_section = False
    current: dict[str, object] | None = None
    for raw_line in path.read_text().splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not in_section:
            if stripped == f"{section}:":
                in_section = True
            continue
        if not line.startswith("  "):
            break
        if stripped.startswith("- "):
            if current:
                entries.append(current)
            current = {}
            body = stripped[2:]
            if ":" in body:
                key, value = body.split(":", 1)
                current[key.strip()] = _coerce_scalar(value.strip())
            continue
        if current is None or ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        current[key.strip()] = _coerce_scalar(value.strip())
    if current:
        entries.append(current)
    return entries


def parse_assignments_list(path: Path) -> list[dict]:
    return _parse_named_entries(path, "assignments")


def parse_ports_registry(path: Path) -> list[dict]:
    return _parse_named_entries(path, "ports")


def parse_backend_assignments(path: Path) -> list[dict]:
    return _parse_named_entries(path, "backends")


def range_for_class(gov: dict, service_class: str) -> tuple[int, int]:
    start = gov.get(f"{service_class}_start")
    end = gov.get(f"{service_class}_end")
    if not isinstance(start, int) or not isinstance(end, int):
        raise SystemExit(f"missing governed range for service class {service_class}")
    return start, end


def compute_occupied_ports(repo_root: Path, gov: dict, assignments: list[dict]) -> set[int]:
    occupied: set[int] = set()
    for port in gov.get("reserved_ports", []):
        if isinstance(port, int) and port > 0:
            occupied.add(port)

    for entry in assignments:
        port = entry.get("host_port")
        if isinstance(port, int) and port > 0:
            occupied.add(port)

    for entry in parse_ports_registry(repo_root / "registry" / "ports.yaml"):
        port = entry.get("port")
        if isinstance(port, int) and port > 0:
            occupied.add(port)

    for entry in parse_backend_assignments(repo_root / "registry" / "backend-assignments.yaml"):
        port = entry.get("host_port")
        if isinstance(port, int) and port > 0:
            occupied.add(port)

    return occupied


def write_assignments_list(path: Path, entries: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["assignments:"]
    for entry in sorted(entries, key=lambda item: (str(item.get("project", "")), str(item.get("service", "")))):
        lines.append(f"  - project: {entry.get('project', '')}")
        lines.append(f"    service: {entry.get('service', '')}")
        lines.append(f"    host_port: {entry.get('host_port', 0)}")
        lines.append(f"    container_port: {entry.get('container_port', 0)}")
        lines.append(f"    bind_host: {entry.get('bind_host', '127.0.0.1')}")
        lines.append(f"    exposure: {entry.get('exposure', 'internal_only')}")
        lines.append(f"    service_class: {entry.get('service_class', 'backend')}")
    path.write_text("\n".join(lines) + "\n")


def collect_bindings(repo_root: Path) -> Iterable[tuple[str, int, str]]:
    for entry in parse_ports_registry(repo_root / "registry" / "ports.yaml"):
        port = entry.get("port")
        if isinstance(port, int) and port > 0:
            bind = str(entry.get("bind_address", "127.0.0.1"))
            label = f"ports:{entry.get('name', 'unknown')}"
            yield bind, port, label

    for entry in parse_assignments_list(repo_root / "registry" / "port_assignments.yaml"):
        port = entry.get("host_port")
        if isinstance(port, int) and port > 0:
            bind = str(entry.get("bind_host", "127.0.0.1"))
            label = f"assignment:{entry.get('project', 'unknown')}:{entry.get('service', 'unknown')}"
            yield bind, port, label

    for entry in parse_backend_assignments(repo_root / "registry" / "backend-assignments.yaml"):
        port = entry.get("host_port")
        if isinstance(port, int) and port > 0:
            bind = str(entry.get("bind_host", "127.0.0.1"))
            label = f"backend:{entry.get('name', 'unknown')}"
            yield bind, port, label
