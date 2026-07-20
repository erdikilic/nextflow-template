#!/usr/bin/env bash
#
# run.sh — convenience launcher. Edit the defaults or override via env / flags.
#   ./run.sh --input samplesheet.csv --outdir results
#   PROFILE=apptainer ./run.sh --input samplesheet.csv
#
set -euo pipefail

PROFILE="${PROFILE:-docker}"
OUTDIR="${OUTDIR:-results}"

exec nextflow run . \
    -profile "${PROFILE}" \
    --outdir "${OUTDIR}" \
    -resume \
    "$@"
