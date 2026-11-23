#!/usr/bin/env python3
"""Check a long-read samplesheet before launching the workflow.

The workflow itself loads ``--input`` into ``SamplesheetRow`` records and checks
each row at launch. This script applies the same rules without Nextflow, for
example in a sample-submission step. It is also a standalone example of the
``bin/`` convention: a small, importable, ``ruff``-clean helper. Replace it with
your own preprocessing as needed.

Rules: the columns are ``sample``, ``fastq`` and an optional ``platform``; a
sample name has no whitespace; ``platform`` is ``ont_r9``, ``ont_r10`` or
``pacbio_hifi``, and an empty or missing cell takes ``--platform`` (default
``ont_r10``); a FASTQ ends with ``.fastq``, ``.fq``, ``.fastq.gz`` or ``.fq.gz``;
a sample split across several FASTQs repeats its name on one row per file,
always with the same platform.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

REQUIRED_COLUMNS = ("sample", "fastq")
PLATFORMS = ("ont_r9", "ont_r10", "pacbio_hifi")
DEFAULT_PLATFORM = "ont_r10"
SAMPLE_PATTERN = re.compile(r"^\S+$")
FASTQ_PATTERN = re.compile(r"^.+\.f(ast)?q(\.gz)?$")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("samplesheet", type=Path, help="Input samplesheet CSV")
    parser.add_argument(
        "--platform",
        choices=PLATFORMS,
        default=DEFAULT_PLATFORM,
        help="Platform of a row whose platform cell is empty or missing (default: %(default)s)",
    )
    return parser.parse_args(argv)


def check(samplesheet: Path, default_platform: str = DEFAULT_PLATFORM) -> list[str]:
    """Return a list of human-readable problems (empty means valid)."""
    problems: list[str] = []
    with samplesheet.open(newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            return [f"missing required column(s): {', '.join(missing)}"]
        platforms: dict[str, str] = {}
        for lineno, row in enumerate(reader, start=2):
            sample = (row.get("sample") or "").strip()
            platform = (row.get("platform") or "").strip() or default_platform
            fastq = (row.get("fastq") or "").strip()
            if not SAMPLE_PATTERN.match(sample):
                problems.append(f"line {lineno}: sample name must not be empty or contain whitespace")
            if platform not in PLATFORMS:
                problems.append(f"line {lineno}: platform must be one of {', '.join(PLATFORMS)}")
            elif platforms.setdefault(sample, platform) != platform:
                problems.append(f"line {lineno}: sample '{sample}' is listed with more than one platform")
            if not FASTQ_PATTERN.match(fastq):
                problems.append(f"line {lineno}: fastq must end with .fastq, .fq, .fastq.gz or .fq.gz")
    return problems


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    problems = check(args.samplesheet, args.platform)
    if problems:
        for problem in problems:
            print(f"ERROR: {problem}", file=sys.stderr)
        return 1
    print(f"OK: {args.samplesheet} looks valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
