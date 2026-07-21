# nextflow-template

[![lint](https://github.com/erdikilic/nextflow-template/actions/workflows/linting.yml/badge.svg)](https://github.com/erdikilic/nextflow-template/actions/workflows/linting.yml)
[![nf-test](https://github.com/erdikilic/nextflow-template/actions/workflows/nf-test.yml/badge.svg)](https://github.com/erdikilic/nextflow-template/actions/workflows/nf-test.yml)
[![functional](https://github.com/erdikilic/nextflow-template/actions/workflows/functional.yml/badge.svg)](https://github.com/erdikilic/nextflow-template/actions/workflows/functional.yml)
[![nextflow-compatibility](https://github.com/erdikilic/nextflow-template/actions/workflows/nextflow-compatibility.yml/badge.svg)](https://github.com/erdikilic/nextflow-template/actions/workflows/nextflow-compatibility.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/erdikilic/nextflow-template/badge)](https://scorecard.dev/viewer/?uri=github.com/erdikilic/nextflow-template)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A526.04.0-brightgreen?labelColor=000000&logo=nextflow)](https://www.nextflow.io/)

A state-of-the-art [Nextflow](https://www.nextflow.io/) DSL2 pipeline template —
a runnable, tool-free skeleton plus the full linting, testing, and CI setup.
Use it with GitHub's **"Use this template"** button, then replace the `EXAMPLE`
module with your real tools.

## Features

- **DSL2 structure** aligned with [nf-core](https://nf-co.re/) conventions:
  `main.nf` → `workflows/` → `subworkflows/local/` → `modules/local/`.
- **Parameter + samplesheet validation** via the `nf-schema` plugin.
- **Config split**: resource labels in `conf/base.config`, per-stage settings in
  `conf/<stage>.config`, container/engine profiles + hardware tiers.
- **Testing**: pipeline-level [nf-test](https://www.nf-test.com/).
- **Linting** (pre-commit + CI): prettier, ruff, hadolint (Dockerfile),
  shellcheck, actionlint, yamllint, markdownlint, gitleaks (secret scan),
  plus `nextflow lint` for the DSL.
- **CI**: lint, nf-test, a real containerised `test,docker` run, a
  Nextflow-version compatibility matrix (min → current → latest), plus
  [OpenSSF Scorecard](https://securityscorecards.dev/) and dependency review.
- **Agent-ready**: `AGENTS.md` (canonical, symlinked to `CLAUDE.md`).

## Quick start

```bash
# 1. Requirements: Nextflow >= 26.04.0, plus Docker/Apptainer/Conda
# 2. Run the bundled minimal test (from the repo root)
nextflow run . -profile test,docker --outdir results

# Or validate wiring without running any tool
nextflow run . -profile test,docker -stub --outdir results_stub
```

Provide your own data with a CSV samplesheet (see [`assets/samplesheet.csv`](assets/samplesheet.csv)):

```bash
nextflow run . --input samplesheet.csv --outdir results -profile docker
```

## Profiles

Engines: `docker`, `apptainer`, `singularity`, `podman`, `conda`.
Hardware tiers: `laptop`, `workstation`, `server`, `hpc`.
Data: `test`, `test_full`. Combine, e.g. `-profile test,docker,workstation`.

## Documentation

- [`docs/usage.md`](docs/usage.md) — inputs, parameters, how to run.
- [`docs/output.md`](docs/output.md) — output directory layout.
- [`AGENTS.md`](AGENTS.md) — conventions for contributors and AI agents.

## Development

```bash
pre-commit install          # enable linters on every commit
pre-commit run --all-files  # run them now
nf-test test                # run the test suite
make help                   # list convenience targets
```

## License

[Apache License 2.0](LICENSE).
