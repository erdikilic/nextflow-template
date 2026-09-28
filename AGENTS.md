# AGENTS.md

Canonical instructions for AI coding agents working in this repository. `CLAUDE.md`
is a symlink to this file. This is the cross-tool standard (Codex and others read
`AGENTS.md` natively); keep it as the single source of truth.

## What this is

A state-of-the-art **Nextflow DSL2** workflow template for **long-read data**
(Oxford Nanopore and PacBio). It ships a runnable, tool-free skeleton (one example
module + subworkflow) plus the full linting, testing, and CI setup. Replace the
`EXAMPLE` module and `INPUT_CHECK` samplesheet schema with your own tools; keep the
structure and conventions.

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
nf-test test --tag example        # one component, by tag
nf-test test --update-snapshot    # re-record snapshots after an intended change

# Lint everything (also runs in CI)
pre-commit run --all-files        # prettier, ruff, hadolint, shellcheck, actionlint, gitleaks, ...
just lint                         # convenience wrapper
```

## Layout

```text
main.nf                     entry: typed params, --help, validation, publish: + output {} block
nextflow.config             defaults, manifest, profiles (docker/apptainer/conda/test + hw tiers)
nextflow_schema.json        parameter schema (nf-schema)
conf/base.config            resource labels (process_single/low/medium/high) + resourceLimits
conf/modules/<stage>.config per-stage ext.args/ext.prefix (one file per logical stage)
workflows/nextflow_template.nf  wires subworkflows + modules
subworkflows/local/<name>/  main.nf + meta.yml + tests/
modules/local/<tool>/       main.nf + environment.yml + meta.yml + tests/
modules/local/handle_data/  merge a sample's many FASTQs (ONT barcode / re-runs)
modules/nf-core/            installed nf-core modules (tracked in modules.json), e.g. sequali
bin/                        executable helper scripts (Python: ruff-clean)
assets/                     samplesheet + schema_input.json + tiny example data
containers/<tool>/Dockerfile   custom images (bare name in module; registry set in config)
tests/                      workflow-level nf-test
docs/                       usage.md + output.md
```

## Conventions (match these when adding code)

- **DSL2, 4-space indentation.** Process names `UPPERCASE_WITH_UNDERSCORES`.
- **Every component is a directory.** A module holds `main.nf`, `environment.yml`,
  `meta.yml` and `tests/main.nf.test` (+ the committed `.snap`); a subworkflow holds
  `main.nf`, `meta.yml` and `tests/`. The directory mirrors the process name:
  `<tool>/<subcommand>/` for `TOOL_SUBCOMMAND`, and a single directory named after
  the task for local utility processes (`handle_data/` -> `HANDLE_DATA`).
- **Long reads only.** `platform` is `nanopore` or `pacbio`; the samplesheet has one
  `fastq` column and no pairing. Do not reintroduce short-read concepts such as
  `single_end`, `fastq_2` or R1/R2 handling.
- **Channels carry `[ val(meta), path(...) ]`.** `meta` has `id` and `platform`, set
  by `INPUT_CHECK`, so modules can branch (e.g. `minimap2 -x map-ont` vs `-x map-hifi`).
- **Conda comes from `environment.yml`**: `conda "${moduleDir}/environment.yml"`,
  never an inline dependency string.
- **Versions travel on the `versions` topic**, one entry per tool:
  `tuple val("${task.process}"), val('<tool>'), eval('<version command>'), emit: versions_<tool>, topic: versions`.
  `NEXTFLOW_TEMPLATE` collates the topic into `workflow_info/collated_versions.yml`, so a new
  stage needs no channel plumbing. The eval command also runs under `-stub`, so it
  must resolve inside the module's container or conda environment.
- **Every process has a `stub:` block** so `-stub` validates wiring without running
  the tool.
- **Every component has an nf-test** with tags (`modules` / `modules_local` /
  `<name>`, or `subworkflows` / `subworkflows_local` / `<name>`) and a committed
  snapshot. Snapshot deterministic outputs only: assert a tool version by shape,
  because it follows whichever engine the suite runs under.
- **Results are published through workflow outputs**, never `publishDir`. The
  entry workflow's `publish:` section names the channels to keep and the
  `output {}` block in `main.nf` places them under `outputDir` (= `--outdir`).
  Give a per-sample output an `index {}` file when a downstream run or a user
  benefits from a samplesheet of it.
- **nf-core modules are installed, not written**: `nf-core modules install <tool>`
  places them under `modules/nf-core/` and records them in `modules.json`. Do not
  edit them in place; tune them through `ext.args` in `conf/modules/<stage>.config`
  and update them with `nf-core modules update`. They keep their own full
  container URLs, and their upstream tests are excluded in `nf-test.config`.
- **Modules stay parameter-agnostic**: tuning comes from `ext.args` / `ext.prefix`
  in `conf/modules/<stage>.config`, never `params.*` read inside the module.
- **`withName:` selectors are PLAIN process names** (`withName: EXAMPLE`), never
  `WORKFLOW:SUBWORKFLOW:PROCESS` — the qualified form silently matches nothing.
- **Container refs are bare names** (`container 'nf-core/ubuntu:22.04'`); the
  registry is set once in `nextflow.config`. Pin an explicit host only for images
  not on that registry.
- **Parameters are declared once.** A parameter read only by the workflow script
  goes in the typed `params {}` block of `main.nf`, with its default and a `//`
  comment. A parameter the configuration reads (`outdir`, `publish_dir_mode`,
  `max_cpus`, ...) goes in `nextflow.config`. `--help` is generated from
  `nextflow_schema.json`, so every parameter also gets a schema entry.
- **Update together**: the parameter declaration, `nextflow_schema.json`, and
  `conf/modules/<stage>.config` whenever you add a parameter or stage.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`); `cliff.toml` maps them into the changelog at tag time.
- **Comments and commit messages are professional and standardised.** In code,
  configs and documentation alike, they describe what something does and why it is
  built that way. They never narrate the history of a change or the discussion that
  produced it: no "now", "no longer", "previously", "as requested", "changed from",
  and no references to a prior revision of the file.

## Adding a new stage (recipe)

1. `modules/local/<tool>/main.nf` — the process (inputs/outputs, container,
   `conda "${moduleDir}/environment.yml"`, a `versions` topic entry, `stub:`).
2. `modules/local/<tool>/environment.yml` and `meta.yml` — the conda spec and the
   documented inputs/outputs.
3. `conf/modules/<stage>.config` — `withName: <PROCESS>` block with `ext.args` /
   `ext.prefix`; add the include to `nextflow.config`.
4. Wire it into `workflows/nextflow_template.nf` (or a subworkflow under
   `subworkflows/local/`) and `emit:` the channels worth keeping.
5. Publish them: add a `publish:` assignment in `main.nf` and a matching target
   in its `output {}` block, then list the files in `docs/output.md`.
6. `modules/local/<tool>/tests/main.nf.test` — tagged test; run
   `nf-test test --update-snapshot` and commit the generated `.snap`.
7. Run `nf-test test` and `pre-commit run --all-files`.

## Do not

- Do not add AI/assistant attribution to commits or PRs (no `Co-Authored-By` /
  "Generated with" trailers).
- Do not commit `work/`, `.nextflow*`, or `results*/` (see `.gitignore`).
- Do not read `params.*` inside a module or a subworkflow; pass values in via
  `take:` or `ext.args`.
- Do not reintroduce Illumina / short-read handling (`single_end`, `fastq_2`, R1/R2).
