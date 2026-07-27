# Contributing

Thanks for contributing! A few conventions keep this repo consistent.

## Workflow

1. Branch from `main` (or work on `main` for small changes).
2. Make your change following the conventions in [`AGENTS.md`](AGENTS.md).
3. Run the checks locally (below).
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
   (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
5. Open a pull request; CI runs linting + nf-test.

```bash
pre-commit run --all-files
nf-test test
```

## Setup

```bash
pip install pre-commit    # or: uv tool install pre-commit
pre-commit install        # lint on every commit
```

Nextflow and nf-test then need to be on your `PATH` separately. To get all of
them pinned to the same versions CI uses, [pixi](https://pixi.sh) does it in one
step instead:

```bash
pixi run setup            # toolchain + git hooks, from pixi.lock
pixi run lint             # equivalent to `pre-commit run --all-files`
pixi run test             # equivalent to `nf-test test`
```

Either route works; pixi is optional. See `pixi task list` for the rest.

## Conventions

See [`AGENTS.md`](AGENTS.md) for the full module/config/naming conventions. In
short: DSL2, 4-space indent, `UPPERCASE` process names, `[meta, files]` channels,
`versions.yml` + `stub:` in every process, tuning via `ext.args` in
`conf/<stage>.config`, plain `withName:` selectors.
