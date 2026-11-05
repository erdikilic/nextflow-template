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

# Tests (nf-test is the standard; they run with -profile test,docker)
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
modules/local/sequali/      per-sample read QC (HTML + JSON report)
bin/                        executable helper scripts (Python: ruff-clean)
assets/                     samplesheet + schema_input.json + tiny example data
containers/<tool>/Dockerfile   custom images (bare name in module; registry set in config)
tests/                      workflow-level nf-test
docs/                       usage.md + output.md
```

## Conventions (match these when adding code)

- **DSL2, formatted by `nextflow lint -format -spaces 4`** (the `nextflow-lint`
  pre-commit hook applies it; `pixi run nf-format` formats the tree). Block
  comments use the `*` form, and a comment that describes a section goes after
  its label (`publish:`, `onComplete:`). Process names
  `UPPERCASE_WITH_UNDERSCORES`.
- **Every component is a directory.** A module holds `main.nf`, `environment.yml`,
  `meta.yml` and `tests/main.nf.test` (+ the committed `.snap`); a subworkflow holds
  `main.nf`, `meta.yml` and `tests/`. The directory mirrors the process name:
  `<tool>/<subcommand>/` for `TOOL_SUBCOMMAND`, and a single directory named after
  the task for local utility processes (`handle_data/` -> `HANDLE_DATA`).
- **Long reads only.** `platform` is `nanopore` or `pacbio`; the samplesheet has one
  `fastq` column and no pairing. Do not reintroduce short-read concepts such as
  `single_end`, `fastq_2` or R1/R2 handling.
- **Static typing in every script.** Each `.nf` file starts with
  `nextflow.enable.types = true`, so `nextflow lint` and the language server
  type-check it. Processes declare typed `input:`, `stage:`, `output:` and `topic:`
  sections; workflows declare typed `take:` and `emit:` (`Channel<T>`, `Value<T>`).
- **Channels carry records, not tuples.** A sample is a record such as
  `record(id: 'S1', platform: Platform.nanopore, fastq: file(...))`, its fields
  read by name. A record type is declared next to the workflow that produces it
  (`Platform`, `SamplesheetRow` and `SampleReads` in `INPUT_CHECK`; `Sample` and
  `SampleResult` in `NEXTFLOW_TEMPLATE`; `ToolVersion` in `main.nf`) and included
  by name where it is needed. A module declares a destructured record input with only
  the fields it reads, e.g. `record(id: String, fastq: Path)`, and returns
  `record(id: id, <name>: file(...))`; the calling workflow joins results back with
  `join(other, by: 'id')`. `platform` stays on the sample record, so a stage can
  branch on it (e.g. `minimap2 -x map-ont` vs `-x map-hifi`).
- **Core operators only**: `map`, `filter`, `flatMap`, `groupBy`, `join(by:)`,
  `combine`, `mix`, `collect`, `unique`, `view`. Legacy operators (`groupTuple`,
  `branch`, `multiMap`, `set`, `tap`, `collectFile`, `splitCsv`, ...) defeat the type
  checker; the static-typing operator guide in the Nextflow docs lists each
  replacement.
- **Conda comes from `environment.yml`**: `conda "${moduleDir}/environment.yml"`,
  never an inline dependency string.
- **Versions travel on the `versions` topic**, one entry per tool, from the
  process `topic:` section:
  `record(process: task.process, tool: '<tool>', version: eval('<version command>')) >> 'versions'`.
  The entry workflow publishes the topic as `workflow_info/versions.yml`, so a new
  stage needs no channel plumbing. The eval command also runs under `-stub`, so it
  must resolve inside the module's container or conda environment.
- **Every process has a `stub:` block** so `-stub` validates wiring without running
  the tool.
- **Processes have no `when:` section** (deprecated in Nextflow 26.10). Skip a
  stage with an `if` in the calling workflow, or disable a process at runtime with
  `process.when` in `conf/modules/<stage>.config`.
- **Every component has an nf-test** with tags (`modules` / `modules_local` /
  `<name>`, or `subworkflows` / `subworkflows_local` / `<name>`) and a committed
  snapshot. Test inputs are built with `record(...)`, and a typed process's output
  records arrive in `process.out[0]`. Snapshot deterministic outputs only; tool
  versions are not process outputs, and the workflow test checks `versions.yml`.
- **Results are published through workflow outputs**, never `publishDir`. The
  entry workflow's `publish:` section names the channels to keep and the
  `output {}` block in `main.nf` places them under `outputDir` (= `--outdir`).
  Give a per-sample output an `index {}` file when a downstream run or a user
  benefits from a samplesheet of it.
- **Files are renamed or routed in the `output {}` block**: a target's `path`
  closure returns a map from each file to its destination. `publishDir` and its
  `saveAs` option are not used.
- **Modules are written in this repository** under `modules/local/`; no module is
  installed from an external registry, so every process follows the conventions
  above and is tested here.
- **Modules stay parameter-agnostic**: tuning comes from `ext.args` / `ext.prefix`
  in `conf/modules/<stage>.config`, never `params.*` read inside the module.
- **`withName:` selectors are PLAIN process names** (`withName: EXAMPLE`), never
  `WORKFLOW:SUBWORKFLOW:PROCESS` — the qualified form silently matches nothing.
- **Container refs are bare names** (`container 'nf-core/ubuntu:22.04'`); the
  registry is set once in `nextflow.config`. Pin an explicit host only for images
  not on that registry.
- **Parameters are declared once.** A parameter the workflow script reads goes in
  the typed `params {}` block of `main.nf`, with its default and a `//` comment;
  Nextflow converts each CLI value to the declared type and rejects an undeclared
  parameter. A parameter only the configuration reads (`outdir`,
  `publish_dir_mode`, `max_cpus`, ...) goes in `nextflow.config`. The samplesheet
  is `input: Channel<SamplesheetRow>?`: Nextflow loads the file into records and
  converts each row to that type, so the record type is the samplesheet schema.
  `--help` is generated from `nextflow_schema.json`, so every parameter also gets a
  schema entry.
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

1. `modules/local/<tool>/main.nf` — a typed process (`nextflow.enable.types = true`,
   a destructured record input, a record output keyed by `id`, container,
   `conda "${moduleDir}/environment.yml"`, a `versions` topic entry, `stub:`).
2. `modules/local/<tool>/environment.yml` and `meta.yml` — the conda spec and the
   documented inputs/outputs.
3. `conf/modules/<stage>.config` — `withName: <PROCESS>` block with `ext.args` /
   `ext.prefix` (closures read the process inputs, e.g. `ext.prefix = { id }`); add
   the include to `nextflow.config`.
4. Wire it into `workflows/nextflow_template.nf` (or a subworkflow under
   `subworkflows/local/`): pass it the sample records, join its output back by
   `id`, and add the new fields to `SampleResult` in `workflows/nextflow_template.nf`.
5. Publish them: add a `publish:` assignment in `main.nf` and a matching target
   in its `output {}` block, then list the files in `docs/output.md`.
6. `modules/local/<tool>/tests/main.nf.test` — tagged test with `record(...)`
   inputs; run
   `nf-test test --update-snapshot` and commit the generated `.snap`.
7. Run `nf-test test` and `pre-commit run --all-files`.

## Reusing an expensive intermediate (recipe)

`storeDir` is deprecated in Nextflow 26.10. An output that is costly to rebuild
and stable across runs, such as a minimap2 index, is reused through workflow
logic instead:

1. Declare the prebuilt file as an optional typed parameter in the `params {}`
   block of `main.nf`, next to the input it is built from, and add both to
   `nextflow_schema.json`.

   ```nextflow
   // Reference FASTA; the minimap2 index is built from it when --index is unset.
   fasta: Path?

   // Prebuilt minimap2 index (.mmi), for example one published by an earlier run.
   index: Path?
   ```

2. Pass both into the named workflow through `take:` (`fasta: Path?`,
   `index: Path?`) and build the index only when none is given:

   ```nextflow
   val_index = index
       ? channel.value(index)
       : MINIMAP2_INDEX(record(id: fasta.baseName, fasta: fasta)).map { r -> r.index }
   ```

3. Emit `val_index` and publish it, so the published file can be passed back with
   `--index` on the next run.

## Do not

- Do not add AI/assistant attribution to commits or PRs (no `Co-Authored-By` /
  "Generated with" trailers).
- Do not commit `work/`, `.nextflow*`, or `results*/` (see `.gitignore`).
- Do not read `params.*` inside a module or a subworkflow; pass values in via
  `take:` or `ext.args`.
- Do not use the `publishDir` or `storeDir` directives; publish through workflow
  outputs and reuse intermediates through workflow logic.
- Do not reintroduce Illumina / short-read handling (`single_end`, `fastq_2`, R1/R2).
