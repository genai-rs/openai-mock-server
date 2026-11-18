#!/usr/bin/env python3
"""Checks the hand-written Cargo.toml against the manifest the generator wrote.

The API features (every feature but `default`) must be the generator's, and every dependency of the generated code
must be declared, optional where the generator made it optional. Usage: check_manifest.py <generated> <ours>
"""

import sys
import tomllib


def load(path: str) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)


def problems(generated: dict, ours: dict) -> list[str]:
    found = []
    theirs = {k: sorted(v) for k, v in generated.get("features", {}).items() if k != "default"}
    mine = {k: sorted(v) for k, v in ours.get("features", {}).items() if k != "default"}
    for name in sorted(theirs.keys() - mine.keys()):
        found.append(f"feature {name} = {theirs[name]} is missing")
    for name in sorted(mine.keys() - theirs.keys()):
        found.append(f"feature {name} is not one of the generator's")
    for name in sorted(theirs.keys() & mine.keys()):
        if theirs[name] != mine[name]:
            found.append(f"feature {name} is {mine[name]}, the generator's is {theirs[name]}")
    dependencies = ours.get("dependencies", {})
    for name, spec in sorted(generated.get("dependencies", {}).items()):
        if name not in dependencies:
            found.append(f"dependency {name} is missing")
            continue
        optional = isinstance(spec, dict) and spec.get("optional", False)
        declared = dependencies[name]
        if optional != (isinstance(declared, dict) and declared.get("optional", False)):
            found.append(f"dependency {name} must {'be' if optional else 'not be'} optional")
    return found


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    found = problems(load(argv[1]), load(argv[2]))
    for problem in found:
        print(f"Cargo.toml: {problem}", file=sys.stderr)
    if found:
        print("Copy the [features] section (but `default`) and the dependencies from target/generated/Cargo.toml.", file=sys.stderr)
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
