#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    <PIPELINE_NAME>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A Nextflow DSL2 pipeline scaffolded from nextflow-template.
    Replace this header, the EXAMPLE module, and the schema with your own tools.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

// Typed declarations so the strict (v2) parser coerces CLI values instead of
// leaving them as Strings. Without this, `--max_cpus 14` / `--max_memory 30.GB`
// arrive as Strings and break the [N, cap].min() resource caps in conf/base.config,
// and `--help false` arrives as the truthy String "false". Types only — defaults
// live in nextflow.config (single source of truth).
params {
    max_cpus: Integer
    max_memory: nextflow.util.MemoryUnit
    help: Boolean
    monochrome_logs: Boolean
}

include { validateParameters ; paramsSummaryLog } from 'plugin/nf-schema'
include { PIPELINE                             } from './workflows/pipeline'

workflow {

    // Print help and exit when --help is set.
    if (params.help) {
        log.info paramsSummaryLog(workflow)
        log.info "Run with --input <samplesheet.csv> --outdir <dir> -profile <docker/apptainer/conda>,<test>"
        exit 0
    }

    // Print a summary when the run finishes. The handler delegates to a
    // top-level function: `params`/`workflow`/`log` are null inside the deferred
    // closure itself, but resolve normally inside a function it calls.
    // Registered here (not at top level) because the strict parser rejects a
    // top-level `workflow.onComplete` statement. Registered before validation so
    // it still prints if `validateParameters()` fails.
    workflow.onComplete {
        completionSummary()
    }

    // Validate CLI parameters against nextflow_schema.json (nf-schema plugin).
    validateParameters()
    log.info paramsSummaryLog(workflow)

    PIPELINE()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Helpers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// One-run summary printed from workflow.onComplete. A function (not the closure
// itself) so `params` / `workflow` / `log` resolve — see the onComplete note above.
def completionSummary() {
    def colour = logColours(params.monochrome_logs)
    def status = workflow.success
        ? "${colour.green}Succeeded${colour.reset}"
        : "${colour.red}Failed${colour.reset}"
    def rule = "${colour.dim}${'-' * 62}${colour.reset}"

    log.info(
        """
        ${rule}
        ${workflow.manifest.name} ${workflow.manifest.version} — ${status}
        ${rule}
        Duration    : ${workflow.duration}
        Completed   : ${workflow.complete}
        Exit status : ${workflow.exitStatus != null ? workflow.exitStatus : '-'}
        Work dir    : ${workflow.workDir}
        Results     : ${params.outdir}
        Reports     : ${params.outdir}/pipeline_info
        ${rule}
        """.stripIndent()
    )

    if (!workflow.success) {
        def reason = workflow.errorMessage ? ": ${workflow.errorMessage}" : ''
        log.error("${colour.red}Pipeline failed${colour.reset}${reason}")
    }
}

// ANSI colour codes, blanked out when --monochrome_logs is set.
def logColours(monochrome) {
    [
        reset: monochrome ? '' : "\033[0m",
        red:   monochrome ? '' : "\033[0;31m",
        green: monochrome ? '' : "\033[0;32m",
        dim:   monochrome ? '' : "\033[2m",
    ]
}
