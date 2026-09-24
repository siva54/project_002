"""Portable launcher contracts; run with Python's unittest discovery."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("project", Path(__file__).parents[1] / "project.py")
project = importlib.util.module_from_spec(spec)
spec.loader.exec_module(project)


class LauncherTests(unittest.TestCase):
    def test_explicit_path_with_spaces_and_missing_override(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(project.shutil, "which", return_value=None):
            executable = Path(directory) / "Godot Engine.exe"
            executable.touch()
            self.assertEqual(project.find_godot(str(executable)), str(executable.resolve()))
            with self.assertRaises(FileNotFoundError):
                project.find_godot(str(executable) + "-missing")

    def test_mac_app_discovery_without_path(self):
        expected = Path("/Applications/Godot.app/Contents/MacOS/Godot")
        with patch.object(project.shutil, "which", return_value=None), patch.object(project.Path, "is_file", lambda p: p == expected):
            self.assertEqual(project.find_godot(system="Darwin"), str(expected))

    def test_check_includes_martial_arts_suite(self):
        with patch.object(project.sys, "argv", ["project.py", "check"]), patch.object(project, "find_godot", return_value="godot"), patch.object(project, "checked_run", return_value=0) as run:
            self.assertEqual(project.main(), 0)
            self.assertEqual(run.call_count, 5)
            self.assertEqual(run.call_args.args[0][-1], "res://tests/run_kung_fu_tests.gd")
            self.assertIn(["--headless", "--fixed-fps", "60", "--script"], [run.call_args.args[0][i:i + 4] for i in range(len(run.call_args.args[0]) - 3)])

    def test_combat_check_runs_only_active_suite_after_import(self):
        with patch.object(project.sys, "argv", ["project.py", "check", "combat"]), patch.object(project, "find_godot", return_value="godot"), patch.object(project, "checked_run", return_value=0) as run:
            self.assertEqual(project.main(), 0)
            self.assertEqual(run.call_count, 2)
            self.assertEqual(run.call_args.args[0][-5:], ["--headless", "--fixed-fps", "60", "--script", "res://tests/run_kung_fu_tests.gd"])

    def test_windows_nested_winget_prefers_console(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(project.os.environ, {"LOCALAPPDATA": directory}), patch.object(project.shutil, "which", return_value=None):
            package = Path(directory) / "Microsoft/WinGet/Packages/GodotEngine.GodotEngine_test/nested"
            package.mkdir(parents=True)
            (package / "Godot_v4_win64.exe").touch()
            console = package / "Godot_v4_win64_console.exe"
            console.touch()
            self.assertEqual(project.find_godot(system="Windows"), str(console))

    def test_script_errors_fail_even_with_zero_exit(self):
        result = subprocess.CompletedProcess([], 0, "SCRIPT ERROR: parse failed\n")
        with patch.object(project.subprocess, "run", return_value=result), patch("builtins.print"):
            self.assertEqual(project.checked_run(["godot"]), 1)

    def test_play_passes_executable_as_one_argument(self):
        with patch.object(project.sys, "argv", ["project.py", "play", "--quit-after", "1"]), patch.object(project, "find_godot", return_value="C:/Game Tools/Godot.exe"), patch.object(project.subprocess, "call", return_value=7) as call:
            self.assertEqual(project.main(), 7)
            self.assertEqual(call.call_args.args[0], ["C:/Game Tools/Godot.exe", "--path", str(project.CLIENT), "--quit-after", "1"])

    def test_check_uses_save_guard_when_available(self):
        with patch.object(project.sys, "argv", ["project.py", "check", "--jobs", "2"]), patch.object(project, "find_godot", return_value="godot"), patch.object(project, "USE_ISOLATED_QA", True), patch.object(project.Path, "is_file", return_value=True), patch.object(project.subprocess, "call", return_value=0) as call:
            self.assertEqual(project.main(), 0)
            self.assertEqual(call.call_args.args[0], [project.sys.executable, str(project.ISOLATED_CHECKS), "--godot", "godot", "--check", "--jobs", "2"])

    def test_missing_save_guard_never_falls_back(self):
        with patch.object(project.sys, "argv", ["project.py", "check"]), patch.object(project, "find_godot", return_value="godot"), patch.object(project, "USE_ISOLATED_QA", True), patch.object(project.Path, "is_file", return_value=False), patch.object(project.subprocess, "call") as call, patch("builtins.print"):
            self.assertEqual(project.main(), 1)
            call.assert_not_called()

    def test_project_two_stops_on_first_failure(self):
        with patch.object(project.sys, "argv", ["project.py", "check"]), patch.object(project, "find_godot", return_value="godot"), patch.object(project, "USE_ISOLATED_QA", False), patch.object(project, "checked_run", side_effect=[0, 1]) as run:
            self.assertEqual(project.main(), 1)
            self.assertEqual(run.call_count, 2)
            self.assertEqual(run.call_args.args[0][-1], "res://tests/run_tests.gd")
