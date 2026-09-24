#!/usr/bin/env python3
"""Portable Makefile commands. Requires Python 3; no shell-specific launch code."""
import argparse
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "client"
ISOLATED_CHECKS = CLIENT / "tools/run_isolated_checks.py"
USE_ISOLATED_QA = False


def find_godot(override="", system=None):
    system = system or platform.system()
    if override:
        resolved = shutil.which(override)
        candidate = Path(override).expanduser()
        if resolved:
            return resolved
        if candidate.is_file():
            return str(candidate.resolve())
        raise FileNotFoundError("GODOT executable does not exist: " + override)
    for name in ("godot", "godot4", "godot_console"):
        found = shutil.which(name)
        if found:
            return found
    candidates = []
    if system == "Darwin":
        candidates = [Path("/Applications/Godot.app/Contents/MacOS/Godot"),
                      Path.home() / "Applications/Godot.app/Contents/MacOS/Godot",
                      Path("/opt/homebrew/bin/godot"), Path("/usr/local/bin/godot")]
    elif system == "Windows":
        local = os.environ.get("LOCALAPPDATA")
        if local:
            packages = Path(local) / "Microsoft/WinGet/Packages"
            candidates = sorted(packages.glob("GodotEngine.GodotEngine_*/**/Godot*_console.exe"), reverse=True)
            candidates += sorted(packages.glob("GodotEngine.GodotEngine_*/**/Godot*.exe"), reverse=True)
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)
    raise FileNotFoundError('Godot 4 was not found. Add it to PATH or run make GODOT="/path/to/Godot executable" <target>.')


def checked_run(command):
    """Godot can report a script error while returning exit code zero."""
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, errors="replace", timeout=300)
    bad_output = any(line.startswith(("SCRIPT ERROR:", "ERROR:", "FAIL:"))
                     for line in result.stdout.splitlines())
    if result.returncode or bad_output:
        print(result.stdout, end="")
        return result.returncode or 1
    print("PASS: " + " ".join(command[1:]))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", ""))
    parser.add_argument("command", choices=("doctor", "play", "editor", "check", "smoke", "import"))
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    try:
        godot = find_godot(options.godot)
        command = [godot, "--path", str(CLIENT)]
        if options.command == "doctor":
            print("OS: " + platform.system(), flush=True)
            print("Python: " + sys.executable, flush=True)
            print("Godot: " + godot, flush=True)
            return subprocess.call([godot, "--version"], cwd=ROOT)
        if options.command in ("play", "editor"):
            if options.command == "editor":
                command.append("--editor")
            return subprocess.call(command + options.args, cwd=ROOT)
        if USE_ISOLATED_QA:
            if not ISOLATED_CHECKS.is_file():
                raise FileNotFoundError("Isolated QA wrapper is missing; refusing to run checks without save protection.")
            mode = {"check": ["--check"], "smoke": ["--group", "smoke"], "import": ["--import"]}
            return subprocess.call([sys.executable, str(ISOLATED_CHECKS), "--godot", godot]
                                   + mode[options.command] + options.args, cwd=ROOT)
        if options.args:
            parser.error("Extra check arguments are only supported by Project 1's isolated runner.")
        # Project 2 has no persistent player saves; import first, then test serially.
        result = checked_run(command + ["--headless", "--editor", "--quit"])
        if result or options.command == "import":
            return result
        if options.command == "smoke":
            return checked_run(command + ["--headless", "--quit-after", "60"])
        for suite in ("run_tests.gd", "run_power_tests.gd", "run_martial_tests.gd", "run_kung_fu_tests.gd"):
            result = checked_run(command + ["--headless", "--script", "res://tests/" + suite])
            if result:
                return result
        return 0
    except (OSError, subprocess.TimeoutExpired) as error:
        print("ERROR: " + str(error), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
