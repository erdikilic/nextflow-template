/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: PIPELINE — wire subworkflows and modules together
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK } from '../subworkflows/local/input_check/main'
include { HANDLE_DATA } from '../modules/local/handle_data/main'
include { EXAMPLE     } from '../modules/local/example/main'

workflow PIPELINE {

    main:
    ch_versions = channel.empty()

    // 1. Parse + validate the samplesheet, grouping multi-file samples.
    INPUT_CHECK()

    // 2. Merge each sample's files into one FASTQ / pair (ONT-aware).
    HANDLE_DATA(INPUT_CHECK.out.reads)
    ch_versions = ch_versions.mix(HANDLE_DATA.out.versions.first())

    // 3. Example per-sample process (replace with your real stages).
    EXAMPLE(HANDLE_DATA.out.reads)
    ch_versions = ch_versions.mix(EXAMPLE.out.versions.first())

    // 4. Collate tool versions.
    ch_versions
        .collectFile(name: 'collated_versions.yml', storeDir: "${params.outdir}/pipeline_info")

    emit:
    reads    = HANDLE_DATA.out.reads
    counts   = EXAMPLE.out.counts
    versions = ch_versions
}
