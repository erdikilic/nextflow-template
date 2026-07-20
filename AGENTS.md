# AGENTS.md

Canonical instructions for AI coding agents working in this repository. `CLAUDE.md`
is a symlink to this file. This is the cross-tool standard (Codex and others read
`AGENTS.md` natively); keep it as the single source of truth.

## What this is

A state-of-the-art **Nextflow DSL2** pipeline template. It ships a runnable,
tool-free skeleton (one example module + subworkflow) plus the full linting,
testing, and CI setup. Replace the `EXAMPLE` module and `INPUT_CHECK` samplesheet
schema with your own tools; keep the structure and conventions.

## Commands

```bash
# Run the minimal test end-to-end (from the repo root)
nextflow run . -profile test,docker --outdir results

# Validate wiring without running tools
nextflow run . -profile test,docker -stub --outdir results_stub

# Parse config / catch syntax errors without running
nextflow config . -profile test

# Tests (nf-test is the standard)
nf-test test                      # all tests
nf-test test tests/default.nf.test

# Lint everything (also runs in CI)
pre-commit run --all-files        # prettier, ruff, hadolint, shellcheck, actionlint, gitleaks, ...
make lint                         # convenience wrapper
```

## Layout

```text
main.nf                     entry: nf-schema validation -> workflows/pipeline.nf
nextflow.config             defaults, manifest, profiles (docker/apptainer/conda/test + hw tiers)
nextflow_schema.json        parameter schema (nf-schema)
conf/base.config            resource labels (process_single/low/medium/high) + check_max()
conf/<stage>.config         per-stage publishDir/ext.args (one file per logical stage)
workflows/pipeline.nf       wires subworkflows + modules
subworkflows/local/input_check/  parse/validate samplesheet, group multi-file samples
modules/local/handle_data/  merge a sample's many FASTQs (ONT barcode / lanes); ONT-aware
modules/local/<tool>/main.nf   one process per tool
modules/nf-core/            installed nf-core modules (tracked in modules.json)
bin/                        executable helper scripts (Python: ruff-clean)
assets/                     samplesheet + schema_input.json + tiny example data
containers/<tool>/Dockerfile   custom images (bare name in module; registry set in config)
tests/                      pipeline-level nf-test
docs/                       usage.md + output.md
```

## Conventions (match these when adding code)

- **DSL2, 4-space indentation.** Process names `UPPERCASE_WITH_UNDERSCORES`;
  module files `modules/local/<tool>/main.nf`.
- **Channels carry `[ val(meta), path(...) ]`.** `meta` has at least `id` and
  `platform` (`illumina`/`nanopore`/`pacbio`), plus `single_end` and `long_reads`
  set by `INPUT_CHECK`. Supports both short-read and long-read (ONT/PacBio) inputs.
- **Every process emits `versions.yml`** via a heredoc, and has a matching `stub:`
  block so `-stub` runs without the tool.
- **Modules stay parameter-agnostic**: tuning comes from `ext.args` / `ext.prefix`
  in `conf/<stage>.config`, never `params.*` read inside the module.
- **`withName:` selectors are PLAIN process names** (`withName: EXAMPLE`), never
  `WORKFLOW:SUBWORKFLOW:PROCESS` — the qualified form silently matches nothing.
- **Container refs are bare names** (`container 'nf-core/ubuntu:22.04'`); the
  registry is set once in `nextflow.config`. Pin an explicit host only for images
  not on that registry.
- **Update together**: `nextflow_schema.json`, the `--help` text, and
  `conf/<stage>.config` whenever you add a parameter or stage.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`); `cliff.toml` maps them into the changelog at tag time.

## Adding a new stage (recipe)

1. `modules/local/<tool>/main.nf` — the process (inputs/outputs, container, conda,
   `versions.yml`, `stub:`).
2. `conf/<stage>.config` — `withName: <PROCESS>` block; add the include to
   `nextflow.config`.
3. Wire it into `workflows/pipeline.nf` (or a subworkflow under
   `subworkflows/local/`).
4. Add an nf-test; run `nf-test test` and `pre-commit run --all-files`.

## Do not

- Do not add AI/assistant attribution to commits or PRs (no `Co-Authored-By` /
  "Generated with" trailers).
- Do not commit `work/`, `.nextflow*`, or `results*/` (see `.gitignore`).
- Do not read `params.*` inside a module.
