#!/usr/bin/env python3
"""Lightweight samplesheet sanity-check.

Parameter validation is handled by the nf-schema plugin at runtime
(``assets/schema_input.json``). This script is a standalone example of the
``bin/`` convention: a small, importable, ``ruff``-clean helper you can call
outside Nextflow. Replace it with your own preprocessing as needed.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

REQUIRED_COLUMNS = ("sample", "fastq_1")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("samplesheet", type=Path, help="Input samplesheet CSV")
    return parser.parse_args(argv)


def check(samplesheet: Path) -> list[str]:
    """Return a list of human-readable problems (empty means valid)."""
    problems: list[str] = []
    with samplesheet.open(newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            return [f"missing required column(s): {', '.join(missing)}"]
        seen: set[str] = set()
        for lineno, row in enumerate(reader, start=2):
            sample = (row.get("sample") or "").strip()
            if not sample:
                problems.append(f"line {lineno}: empty sample name")
            elif sample in seen:
                problems.append(f"line {lineno}: duplicate sample '{sample}'")
            else:
                seen.add(sample)
            if not (row.get("fastq_1") or "").strip():
                problems.append(f"line {lineno}: empty fastq_1")
    return problems


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    problems = check(args.samplesheet)
    if problems:
        for problem in problems:
            print(f"ERROR: {problem}", file=sys.stderr)
        return 1
    print(f"OK: {args.samplesheet} looks valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
