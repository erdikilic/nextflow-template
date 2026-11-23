#!/usr/bin/env bash
# Checks every component against the Nextflow module registry rules with
# `nextflow module validate`. A component is a directory holding a main.nf under
# modules/local/ or subworkflows/local/, nested stages included.
#
# A module under modules/local/ meets every rule. A scope or stage under
# subworkflows/local/ includes its stages and steps by relative path, which the
# registry rule on includes forbids; it passes when that rule is its only
# diagnostic. Validator output in any other form fails the check, so a changed
# message cannot pass unnoticed. Ends with one summary line.
#
# Usage: .github/scripts/validate-components.sh   (run with Nextflow on PATH)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

passed='Module validation passed.'
failed='Module validation failed:'
local_include="^  - Module script includes a local module '[^']+' -- a module can only include registry modules\$"

full=0
relaxed=0
failures=0

while IFS= read -r script; do
    dir="${script%/main.nf}"
    validate_status=0
    output=$(nextflow module validate "./$dir" 2>&1) || validate_status=$?

    if [[ $validate_status -eq 0 && "$output" == "$passed" ]]; then
        echo "full:                   $dir"
        full=$((full + 1))
        continue
    fi

    # Anything but the local-include rule fails the component.
    verdict=allowed
    if [[ "$dir" != subworkflows/local/* || $validate_status -eq 0 ]]; then
        verdict=failed
    else
        header=''
        diagnostics=0
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ -z "$header" ]]; then
                header=$line
                [[ "$header" == "$failed" ]] || verdict=unrecognized
            elif [[ "$line" =~ $local_include ]]; then
                diagnostics=$((diagnostics + 1))
            elif [[ "$line" == '  - '* ]]; then
                verdict=failed
            else
                verdict=unrecognized
            fi
        done <<<"$output"
        if [[ "$verdict" == allowed && $diagnostics -eq 0 ]]; then
            verdict=unrecognized
        fi
    fi

    case $verdict in
        allowed)
            echo "local includes allowed: $dir"
            relaxed=$((relaxed + 1))
            ;;
        failed)
            echo "FAILED:                 $dir"
            printf '%s\n' "$output"
            failures=$((failures + 1))
            ;;
        *)
            echo "UNRECOGNIZED OUTPUT:    $dir (exit status $validate_status)"
            printf '%s\n' "$output"
            failures=$((failures + 1))
            ;;
    esac
done < <(find modules/local subworkflows/local -name main.nf ! -path '*/tests/*' | sort)

total=$((full + relaxed + failures))
summary="${total} components: ${full} fully validated, ${relaxed} with local includes allowed, ${failures} failed"
if [[ $failures -gt 0 ]]; then
    echo "validate-components: FAILED, $summary" >&2
    exit 1
fi
echo "validate-components: $summary"
