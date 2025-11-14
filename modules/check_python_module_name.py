import os
import sys
import re

if not (2 <= len(sys.argv) <= 3):
    sys.exit(f"Usage: {sys.argv[0]} <file> [expected-module-name]")

path = sys.argv[1]

if not os.path.isfile(path) or os.path.splitext(path)[1] not in {".so", ".pyd"}:
    sys.exit(f"Error: Invalid file provided: {path}")

mod_name = None
with open(path, "rb") as f:
    if match := re.search(b"PyInit_([a-zA-Z0-9_]+)", f.read()):
        mod_name = match.group(1).decode("utf-8")

if len(sys.argv) == 3:
    if mod_name != sys.argv[2]:
        sys.exit(
            f"Error: Module name mismatch. Expected '{sys.argv[2]}', found '{mod_name}'."
        )
    sys.exit(0)

print(mod_name)
