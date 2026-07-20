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

    // Validate CLI parameters against nextflow_schema.json (nf-schema plugin).
    validateParameters()
    log.info paramsSummaryLog(workflow)

    PIPELINE()
}
