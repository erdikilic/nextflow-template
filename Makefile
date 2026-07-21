.PHONY: help lint nf-lint format nf-format update test run stub config clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

lint: ## Run all pre-commit linters
	pre-commit run --all-files

nf-lint: ## Lint Nextflow (.nf/.config) for errors + deprecations
	nextflow lint -o concise .

update: ## Bump pre-commit hook / linter tool pins to their latest releases
	pre-commit autoupdate

format: ## Auto-format (prettier + ruff)
	pre-commit run prettier --all-files || true
	pre-commit run ruff-format --all-files || true

nf-format: ## Auto-format Nextflow (.nf/.config) to canonical style
	nextflow lint -format -spaces 4 .

test: ## Run the nf-test suite
	nf-test test

run: ## Run the minimal test end-to-end (docker)
	nextflow run . -profile test,docker --outdir results

stub: ## Validate wiring without running tools
	nextflow run . -profile test,docker -stub --outdir results_stub

config: ## Parse config / catch syntax errors
	nextflow config . -profile test >/dev/null && echo "config OK"

clean: ## Remove run artefacts
	rm -rf work results results_* .nextflow* results_stub .nf-test .nf-test.log
