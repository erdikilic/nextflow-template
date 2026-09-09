# Developer convenience recipes; `just` with no arguments lists them.
#
# The same set is available as pixi tasks (`pixi task list`) for contributors who
# want the pinned toolchain from pixi.lock. These recipes assume the tools are
# already on PATH.

# `nextflow lint` walks the whole tree, and an in-tree env dir (.pixi/, .venv/)
# holds nf-core's Jinja templates, which are not valid Nextflow. Passing -exclude
# REPLACES the built-in default list, so the defaults are restated here.
nf_lint_exclude := "-exclude .git -exclude .lineage -exclude .nextflow " + \
    "-exclude .nf-test -exclude nf-test.config -exclude work " + \
    "-exclude .pixi -exclude .venv"

# Show this help
default:
    @just --list --unsorted

# Run all pre-commit linters
lint:
    pre-commit run --all-files

# Lint Nextflow (.nf/.config) for errors + deprecations
nf-lint:
    nextflow lint -o concise {{ nf_lint_exclude }} .

# Bump pre-commit hook / linter tool pins to their latest releases
update:
    pre-commit autoupdate

# Auto-format (prettier + ruff)
format:
    pre-commit run prettier --all-files || true
    pre-commit run ruff-format --all-files || true

# Auto-format Nextflow (.nf/.config) to canonical style
nf-format:
    nextflow lint -format -spaces 4 {{ nf_lint_exclude }} .

# Run the nf-test suite
test:
    nf-test test

# Run the minimal test end-to-end (docker)
run:
    nextflow run . -profile test,docker --outdir results

# Validate wiring without running tools
stub:
    nextflow run . -profile test,docker -stub --outdir results_stub

# Parse config / catch syntax errors
config:
    nextflow config . -profile test >/dev/null && echo "config OK"

# Remove run artefacts
clean:
    rm -rf work results results_* .nextflow* .nf-test .nf-test.log
