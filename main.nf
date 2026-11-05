#!/usr/bin/env nextflow
/*
 * <WORKFLOW_NAME>
 *
 * A Nextflow DSL2 workflow scaffolded from nextflow-template.
 * Replace this header, the EXAMPLE module, and the schema with your own tools.
 */

nextflow.enable.types = true

include { paramsHelp ; paramsSummaryLog } from 'plugin/nf-schema'
include { NEXTFLOW_TEMPLATE } from './workflows/nextflow_template'
include { SamplesheetRow } from './subworkflows/local/input_check/main'

// Parameters read only by the workflow script. Nextflow converts each CLI value
// to the declared type and rejects a parameter that is declared nowhere.
// Parameters that only the configuration reads (outdir, publish_dir_mode,
// max_cpus, max_memory) are declared in nextflow.config.
// nextflow_schema.json documents every parameter for --help.
params {
    // Samplesheet of long-read inputs (see assets/samplesheet.csv), loaded as a
    // channel of SamplesheetRow records: each row is converted to that type, so
    // an unknown platform or a missing FASTQ fails the run before it starts.
    // Nullable so that --help runs without it.
    input: Channel<SamplesheetRow>?

    // --help lists the top-level parameters; --help <name> shows one in full.
    help: String?

    // With --help, list every non-hidden parameter.
    help_full: Boolean = false

    // With --help, include hidden parameters.
    show_hidden: Boolean = false

    // Strip ANSI colours from the run summary. nextflow.config passes the same
    // value to nf-schema for its help and parameter summary.
    monochrome_logs: Boolean = false
}

workflow {

    main:
    // Print the schema-driven help and exit when --help or --help_full is set.
    // A bare --help arrives as "true"; any other value names a parameter.
    if (params.help || params.help_full) {
        def helpOptions = [
            command: 'nextflow run . -profile <docker/apptainer/conda> --input samplesheet.csv --outdir results',
            fullHelp: params.help_full,
            showHidden: params.show_hidden,
            parameter: params.help && params.help != 'true' ? params.help : null,
        ]
        log.info(paramsHelp(helpOptions))
        exit(0, null)
    }
    if (params.input == null) {
        error('Missing required parameter: --input <samplesheet.csv>')
    }
    log.info(paramsSummaryLog())

    results = NEXTFLOW_TEMPLATE(params.input)

    // Channels written to the output directory; the output block below says
    // where each one goes. Reads are published as samplesheet records so their
    // index file can be passed straight back to --input.
    ch_reads = results.map { r -> record(sample: r.id, platform: r.platform, fastq: r.fastq) }
    ch_qc = results.map { r -> record(sample: r.id, platform: r.platform, html: r.html, json: r.json) }
    ch_counts = results.map { r -> record(sample: r.id, counts: r.counts) }
    ch_versions = channel.topic('versions')
        .unique()
        .collect()
        .flatMap { entries -> entries.toSorted { v -> "${v.process} ${v.tool}" } }

    publish:
    reads: Channel<SamplesheetRow> = ch_reads
    qc: Channel<Record> = ch_qc
    counts: Channel<Record> = ch_counts
    versions: Channel<ToolVersion> = ch_versions

    onComplete:
    // Runs when the workflow finishes, successfully or not.
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
        Exit status : ${workflow.exitStatus == null ? '-' : "${workflow.exitStatus}"}
        Work dir    : ${workflow.workDir}
        Results     : ${workflow.outputDir}
        Reports     : ${workflow.outputDir}/workflow_info
        ${rule}
        """.stripIndent()
    )

    onError:
    // Runs when the workflow fails, before onComplete.
    def reason = workflow.errorMessage ? ": ${workflow.errorMessage}" : ''
    log.error("Workflow failed${reason}")
}

/*
 * Outputs — layout of --outdir (see docs/output.md)
 *
 * Each target publishes the files in the channel of the same name. The root is
 * `outputDir` (= --outdir) and the copy mode is `workflow.output.mode`
 * (= --publish_dir_mode), both set in nextflow.config.
 */

output {
    // One merged FASTQ per sample, indexed by a samplesheet in the input format.
    reads: Channel<SamplesheetRow> {
        label 'reads'
        path 'reads'
        index {
            path 'reads/samplesheet.csv'
            header true
        }
    }

    // Sequali read-QC reports, one HTML and one JSON per sample, indexed by a
    // table that links each sample to its two reports. The map form of `path`
    // gives every file its own target, here <sample>.sequali.<ext>.
    qc: Channel<Record> {
        label 'qc'
        path { r ->
            [
                (r.html): "qc/sequali/${r.sample}.sequali.html",
                (r.json): "qc/sequali/${r.sample}.sequali.json",
            ]
        }
        index {
            path 'qc/sequali/index.csv'
            header true
        }
    }

    // Per-sample output of the EXAMPLE process.
    counts: Channel<Record> {
        label 'example'
        path 'example'
    }

    // Version of every tool that ran, one entry per process and tool.
    versions: Channel<ToolVersion> {
        label 'provenance'
        index {
            path 'workflow_info/versions.yml'
        }
    }
}

// One tool version from the `versions` topic.
record ToolVersion {
    process: String
    tool: String
    version: String
}

/*
 * Helpers
 */

// ANSI colour codes, blanked out when --monochrome_logs is set.
def logColours(monochrome) {
    [
        reset: monochrome ? '' : "\033[0m",
        red: monochrome ? '' : "\033[0;31m",
        green: monochrome ? '' : "\033[0;32m",
        dim: monochrome ? '' : "\033[2m",
    ]
}
