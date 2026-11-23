#!/usr/bin/env bash
# Runs a command with a Nextflow this repository supports first on PATH: the
# pixi environment's Nextflow when .pixi provides one, otherwise the one already
# on PATH. Stops with one line, before the command runs, when that Nextflow is
# older than manifest.nextflowVersion in nextflow.config. The pre-commit hooks
# call Nextflow through this script.
#
# Usage: .github/scripts/with-nextflow.sh <command> [<argument> ...]
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
pixi_bin="$root/.pixi/envs/default/bin"
if [[ -x "$pixi_bin/nextflow" ]]; then
    PATH="$pixi_bin:$PATH"
    export PATH
fi

if ! nextflow=$(command -v nextflow); then
    echo "with-nextflow: no Nextflow found; run 'pixi install' or put Nextflow on PATH" >&2
    exit 1
fi

required=$(sed -n "s/^[[:space:]]*nextflowVersion[[:space:]]*=[[:space:]]*['\"]>=[[:space:]]*\([0-9.]*\).*/\1/p" "$root/nextflow.config")
found=$("$nextflow" -version 2>/dev/null | sed -n 's/^[[:space:]]*version \([0-9][0-9.]*\).*/\1/p' | head -n 1)

# True when version $1 is older than version $2, compared field by field.
older() {
    local -a a b
    IFS=. read -r -a a <<<"$1"
    IFS=. read -r -a b <<<"$2"
    local i
    for i in 0 1 2; do
        if ((10#${a[i]:-0} < 10#${b[i]:-0})); then return 0; fi
        if ((10#${a[i]:-0} > 10#${b[i]:-0})); then return 1; fi
    done
    return 1
}

if [[ -n "$required" ]] && { [[ -z "$found" ]] || older "$found" "$required"; }; then
    echo "with-nextflow: ${nextflow} is Nextflow ${found:-of unknown version}, older than manifest.nextflowVersion >=${required}; run 'pixi install' or put a newer Nextflow on PATH" >&2
    exit 1
fi

exec "$@"
