#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    <WORKFLOW_NAME>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A Nextflow DSL2 workflow scaffolded from nextflow-template.
    Replace this header, the EXAMPLE module, and the schema with your own tools.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsHelp ; paramsSummaryLog ; validateParameters } from 'plugin/nf-schema'
include { NEXTFLOW_TEMPLATE                                } from './workflows/nextflow_template'

// Parameters read only by the workflow script. The declared types make the
// strict parser convert CLI values (`--validate_params false` arrives as a
// Boolean, not the truthy String "false"). Parameters that the configuration
// also reads (outdir, publish_dir_mode, monochrome_logs, max_cpus, max_memory)
// are declared in nextflow.config. nextflow_schema.json documents and validates
// every parameter and is kept in step with both.
params {
    // Samplesheet CSV of long-read inputs (see assets/samplesheet.csv). Nullable
    // so that --help runs without it; nf-schema reports it as required otherwise.
    input: Path?

    // Validate the parameters against nextflow_schema.json before the run starts.
    validate_params: Boolean = true

    // --help lists the top-level parameters; --help <name> shows one in full.
    // Untyped because it takes either form.
    help = false

    // With --help, list every non-hidden parameter.
    help_full: Boolean = false

    // With --help, include hidden parameters.
    show_hidden: Boolean = false
}

workflow {

    main:
    // Print the schema-driven help and exit when --help or --help_full is set.
    // The strict parser passes an untyped CLI flag as a String, so "true" and
    // "false" are read as flags and any other value names a parameter.
    def helpTopic = params.help instanceof String && !(params.help in ['true', 'false']) ? params.help : ''
    if (params.help in [true, 'true'] || helpTopic || params.help_full) {
        def helpOptions = [
            command: 'nextflow run . -profile <docker/apptainer/conda> --input samplesheet.csv --outdir results',
            fullHelp: params.help_full,
            showHidden: params.show_hidden,
        ]
        log.info paramsHelp(helpOptions, helpTopic)
        exit 0
    }

    // Validate the parameters against nextflow_schema.json (nf-schema plugin).
    if (params.validate_params) {
        validateParameters()
    }
    log.info paramsSummaryLog(workflow)

    NEXTFLOW_TEMPLATE(params.input)

    // Runs when the workflow finishes, successfully or not. The failure reason is
    // reported here rather than in an `onError:` section, which Nextflow 26.04
    // invokes with an argument the section cannot accept.
    onComplete:
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
        Reports     : ${params.outdir}/workflow_info
        ${rule}
        """.stripIndent()
    )
    if (!workflow.success) {
        def reason = workflow.errorMessage ? ": ${workflow.errorMessage}" : ''
        log.error("${colour.red}Workflow failed${colour.reset}${reason}")
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Helpers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// ANSI colour codes, blanked out when --monochrome_logs is set.
def logColours(monochrome) {
    [
        reset: monochrome ? '' : "\033[0m",
        red:   monochrome ? '' : "\033[0;31m",
        green: monochrome ? '' : "\033[0;32m",
        dim:   monochrome ? '' : "\033[2m",
    ]
}
