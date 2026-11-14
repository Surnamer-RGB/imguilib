"""Run logic tests with the official Luau CLI; no Roblox client or demo needed."""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau", help="Path to the Luau CLI")
parser.add_argument("--temp-dir", default=None, help="ASCII path for Luau builds without Unicode path support")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "ImGui.luau").read_text(encoding="utf-8")
mock = (root / "tests/mock.luau").read_text(encoding="utf-8")
tests = (root / "tests/core.luau").read_text(encoding="utf-8")
demo = (root / "Demo.luau").read_text(encoding="utf-8")
demo_tests = (root / "tests/demo.luau").read_text(encoding="utf-8")
with tempfile.TemporaryDirectory(prefix="imguilib-test-", dir=args.temp_dir) as directory:
    script = Path(directory) / "suite.luau"
    script.write_text(mock + "\nlocal ImGui = (function()\n" + source + "\nend)()\n" + tests, encoding="utf-8")
    result = subprocess.run([args.luau, str(script)], check=False)
    if result.returncode:
        raise SystemExit(result.returncode)
    script.write_text(mock + "\nlocal ImGui = (function()\n" + source + "\nend)()\n"
                      + "local function runDemo(...)\n" + demo + "\nend\n" + demo_tests, encoding="utf-8")
    raise SystemExit(subprocess.run([args.luau, str(script)], check=False).returncode)
