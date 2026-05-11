#!/usr/bin/env python3
"""Characterization tests for the read-only release gate."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GATE = REPO_ROOT / "release-gate"
MANIFEST = REPO_ROOT / "release-manifest.json"

EXPECTED_RUNTIME_FIXTURE_BLOCKERS = {
    "VERSION_DRIFT",
    "RUNTIME_POLICY_FALSE",
}


def run_gate(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(GATE), *args],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def run_gate_json(*args: str) -> tuple[subprocess.CompletedProcess[str], dict]:
    with tempfile.TemporaryDirectory(prefix="short-drama-gate-test-") as tmp:
        out = Path(tmp) / "report.json"
        result = run_gate(*args, "--json-out", str(out))
        report = json.loads(out.read_text(encoding="utf-8")) if out.exists() else {}
    return result, report


def write_manifest(path: Path, manifest: dict) -> Path:
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


class ReleaseGateTests(unittest.TestCase):
    def load_real_manifest(self) -> dict:
        return json.loads(MANIFEST.read_text(encoding="utf-8"))

    def check_ids(self, report: dict) -> set[str]:
        return set(report["summary"]["checks_failed"])

    def write_runtime_drift_fixture_manifest(self, tmp_path: Path) -> Path:
        runtime_parent = tmp_path / "runtime"
        runtime_root = runtime_parent / "short-drama"
        runtime_root.mkdir(parents=True)
        (runtime_root / "VERSION").write_text("0.0.1\n", encoding="utf-8")
        (runtime_root / "WHATSNEW.md").write_text("**v0.0.1**\n", encoding="utf-8")
        (runtime_parent / "short-drama-remake").mkdir()
        (tmp_path / "short-drama-remake").mkdir()

        manifest = self.load_real_manifest()
        manifest["package_root"] = str(REPO_ROOT / "short-drama")
        manifest["runtime_roots"] = [
            {
                "name": "fixture-runtime",
                "path": str(runtime_root),
                "policy": "generated_copy",
                "required": True,
            }
        ]
        return write_manifest(tmp_path / "release-manifest.json", manifest)

    def test_fixture_full_dry_run_fails_expected_runtime_blockers(self) -> None:
        with tempfile.TemporaryDirectory(prefix="short-drama-gate-runtime-") as tmp:
            manifest_path = self.write_runtime_drift_fixture_manifest(Path(tmp))
            result, report = run_gate_json("--dry-run", "--manifest", str(manifest_path))

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(report["status"], "fail")
        self.assertEqual(self.check_ids(report), EXPECTED_RUNTIME_FIXTURE_BLOCKERS)

    def test_check_version_drift_returns_only_version_drift(self) -> None:
        with tempfile.TemporaryDirectory(prefix="short-drama-gate-runtime-") as tmp:
            manifest_path = self.write_runtime_drift_fixture_manifest(Path(tmp))
            result, report = run_gate_json(
                "--dry-run",
                "--manifest",
                str(manifest_path),
                "--check",
                "VERSION_DRIFT",
            )

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(self.check_ids(report), {"VERSION_DRIFT"})

    def test_check_runtime_policy_false_returns_only_runtime_policy_false(self) -> None:
        with tempfile.TemporaryDirectory(prefix="short-drama-gate-runtime-") as tmp:
            manifest_path = self.write_runtime_drift_fixture_manifest(Path(tmp))
            result, report = run_gate_json(
                "--dry-run",
                "--manifest",
                str(manifest_path),
                "--check",
                "RUNTIME_POLICY_FALSE",
            )

        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(self.check_ids(report), {"RUNTIME_POLICY_FALSE"})

    def test_package_surface_scope_checks_pass_current_package(self) -> None:
        for check_id in (
            "DUPLICATE_AUTHORITY_DOCS",
            "DUPLICATE_AUTHORITY_SCRIPTS",
            "UPDATE_CHECK_SPLIT",
            "UPDATE_REPO_NAME_DRIFT",
        ):
            with self.subTest(check_id=check_id):
                result, report = run_gate_json("--dry-run", "--check", check_id)

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(report["status"], "pass")
                self.assertEqual(self.check_ids(report), set())

    def test_excluded_policy_manifest_passes_runtime_policy_check(self) -> None:
        with tempfile.TemporaryDirectory(prefix="short-drama-gate-excluded-") as tmp:
            tmp_path = Path(tmp)
            manifest = self.load_real_manifest()
            manifest["runtime_roots"] = [
                {
                    "name": item["name"],
                    "path": item["path"],
                    "policy": "intentionally excluded by manifest",
                    "required": item.get("required", True),
                }
                for item in manifest["runtime_roots"]
            ]
            manifest_path = write_manifest(tmp_path / "release-manifest.json", manifest)

            result, report = run_gate_json(
                "--dry-run",
                "--manifest",
                str(manifest_path),
                "--check",
                "RUNTIME_POLICY_FALSE",
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(report["status"], "pass")
        self.assertEqual(self.check_ids(report), set())

    def test_declared_symlink_manifest_passes_runtime_policy_check(self) -> None:
        with tempfile.TemporaryDirectory(prefix="short-drama-gate-symlink-") as tmp:
            tmp_path = Path(tmp)
            target = tmp_path / "target-runtime"
            target.mkdir()
            link = tmp_path / "runtime-link"
            link.symlink_to(target, target_is_directory=True)

            manifest = self.load_real_manifest()
            manifest["package_root"] = "package"
            manifest["runtime_roots"] = [
                {
                    "name": "declared-symlink",
                    "path": str(link),
                    "target": str(target),
                    "policy": "declared symlink",
                    "required": True,
                }
            ]
            manifest_path = write_manifest(tmp_path / "release-manifest.json", manifest)

            result, report = run_gate_json(
                "--dry-run",
                "--manifest",
                str(manifest_path),
                "--check",
                "RUNTIME_POLICY_FALSE",
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(report["status"], "pass")
        self.assertEqual(self.check_ids(report), set())

    def test_unknown_check_id_exits_one(self) -> None:
        result = run_gate("--dry-run", "--check", "NO_SUCH_CHECK")

        self.assertEqual(result.returncode, 1)
        self.assertIn("Unknown check id(s): NO_SUCH_CHECK", result.stderr)


if __name__ == "__main__":
    unittest.main()
