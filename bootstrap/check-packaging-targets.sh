#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export AIAAST_DEFAULT_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import configparser
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate generated packaging manifests, desktop launchers, and any generated "
            "systemd units in an installed repo."
        )
    )
    default_repo = Path(os.environ["AIAAST_DEFAULT_REPO"])
    parser.add_argument("target_repo", nargs="?", default=str(default_repo))
    parser.add_argument("--strict", action="store_true", help="Reserved for parity with other validators.")
    return parser.parse_args()


args = parse_args()
repo = Path(args.target_repo).resolve()
issues: list[str] = []

if not repo.is_dir():
    print(f"Target repo does not exist: {repo}", file=sys.stderr)
    raise SystemExit(1)

packaging_dir = repo / "packaging"
if not packaging_dir.is_dir():
    print("packaging_targets_absent")
    raise SystemExit(0)


def require_file(path: Path) -> None:
    if not path.is_file():
        issues.append(f"Missing packaging file: {path.relative_to(repo)}")


required_files = [
    packaging_dir / "README.md",
    packaging_dir / "appimage.yml",
    packaging_dir / "flatpak-manifest.json",
    packaging_dir / "snapcraft.yaml",
]
for path in required_files:
    require_file(path)

desktop_files = sorted(packaging_dir.glob("*.desktop"))
if not desktop_files:
    issues.append("Missing shared packaging desktop launcher (*.desktop)")

desktop_exec_by_name: dict[str, str] = {}
for desktop in desktop_files:
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read_string(desktop.read_text())
    except Exception as exc:  # noqa: BLE001
        issues.append(f"Invalid desktop file {desktop.relative_to(repo)}: {exc}")
        continue
    if "Desktop Entry" not in parser:
        issues.append(f"Desktop file missing [Desktop Entry] section: {desktop.relative_to(repo)}")
        continue
    section = parser["Desktop Entry"]
    for key in ("Type", "Name", "Exec", "Icon", "Categories"):
        if not section.get(key, "").strip():
            issues.append(f"Desktop file missing required key {key}: {desktop.relative_to(repo)}")
    if section.get("Type", "").strip() != "Application":
        issues.append(f"Desktop file Type must be Application: {desktop.relative_to(repo)}")
    desktop_exec_by_name[desktop.name] = section.get("Exec", "").strip().split()[0]

flatpak_path = packaging_dir / "flatpak-manifest.json"
flatpak_command = ""
if flatpak_path.is_file():
    try:
        manifest = json.loads(flatpak_path.read_text())
    except Exception as exc:  # noqa: BLE001
        issues.append(f"Invalid JSON in {flatpak_path.relative_to(repo)}: {exc}")
    else:
        for key in ("app-id", "runtime", "runtime-version", "sdk", "command"):
            if not isinstance(manifest.get(key), str) or not manifest.get(key, "").strip():
                issues.append(f"{flatpak_path.relative_to(repo)} is missing required string key: {key}")
        flatpak_command = str(manifest.get("command", "")).strip()
        finish_args = manifest.get("finish-args")
        if not isinstance(finish_args, list) or not all(isinstance(item, str) for item in finish_args):
            issues.append(f"{flatpak_path.relative_to(repo)} finish-args must be a list of strings")
        modules = manifest.get("modules")
        if not isinstance(modules, list) or not modules:
            issues.append(f"{flatpak_path.relative_to(repo)} must define at least one module")
        else:
            desktop_refs: list[str] = []
            for module in modules:
                if not isinstance(module, dict):
                    issues.append(f"{flatpak_path.relative_to(repo)} modules entries must be objects")
                    continue
                build_commands = module.get("build-commands")
                sources = module.get("sources")
                if not isinstance(build_commands, list) or not build_commands:
                    issues.append(f"{flatpak_path.relative_to(repo)} module is missing build-commands")
                if not isinstance(sources, list) or not sources:
                    issues.append(f"{flatpak_path.relative_to(repo)} module is missing sources")
                for cmd in build_commands or []:
                    if not isinstance(cmd, str):
                        issues.append(f"{flatpak_path.relative_to(repo)} build-commands entries must be strings")
                        continue
                    match = re.search(r"\./packaging/([A-Za-z0-9._-]+\.desktop)\b", cmd)
                    if match:
                        desktop_refs.append(match.group(1))
            if not desktop_refs:
                issues.append(f"{flatpak_path.relative_to(repo)} does not install a desktop file from packaging/")
            for ref in sorted(set(desktop_refs)):
                if not (packaging_dir / ref).is_file():
                    issues.append(f"Flatpak manifest references missing desktop file: packaging/{ref}")
                elif flatpak_command and desktop_exec_by_name.get(ref) and Path(desktop_exec_by_name[ref]).name != flatpak_command:
                    issues.append(
                        f"Flatpak command {flatpak_command!r} does not match desktop Exec basename "
                        f"{Path(desktop_exec_by_name[ref]).name!r} for packaging/{ref}"
                    )

appimage_path = packaging_dir / "appimage.yml"
if appimage_path.is_file():
    text = appimage_path.read_text()
    for needle in (
        "version:",
        "script:",
        "AppDir:",
        "app_info:",
        "id:",
        "name:",
        "version:",
        "exec:",
        "AppImage:",
    ):
        if needle not in text:
            issues.append(f"{appimage_path.relative_to(repo)} is missing required key: {needle}")
    desktop_refs = re.findall(r"\./packaging/([A-Za-z0-9._-]+\.desktop)\b", text)
    if not desktop_refs:
        issues.append(f"{appimage_path.relative_to(repo)} does not install a desktop file from packaging/")
    for ref in sorted(set(desktop_refs)):
        if not (packaging_dir / ref).is_file():
            issues.append(f"AppImage manifest references missing desktop file: packaging/{ref}")

snap_path = packaging_dir / "snapcraft.yaml"
if snap_path.is_file():
    text = snap_path.read_text()
    for needle in ("name:", "base:", "version:", "grade:", "confinement:", "apps:", "parts:", "command:", "plugin:"):
        if needle not in text:
            issues.append(f"{snap_path.relative_to(repo)} is missing required key: {needle}")
    if "organize:" not in text or "dist/" not in text:
        issues.append(f"{snap_path.relative_to(repo)} is missing dist organize mapping")

systemd_paths: list[Path] = []
for rel_root in ("ops/systemd", "ops/install/build/systemd"):
    root = repo / rel_root
    if root.is_dir():
        systemd_paths.extend(sorted(path for path in root.glob("*.service")))
        systemd_paths.extend(sorted(path for path in root.glob("*.timer")))

if systemd_paths and shutil.which("systemd-analyze"):
    verify = subprocess.run(
        ["systemd-analyze", "verify", *[str(path) for path in systemd_paths]],
        cwd=repo,
        text=True,
        capture_output=True,
    )
    if verify.returncode != 0:
        stderr = (verify.stderr or verify.stdout).strip()
        issues.append(f"systemd-analyze verify failed for generated units: {stderr or 'unknown error'}")

if issues:
    print("packaging_targets_issues_detected")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("packaging_targets_ok")
PY
