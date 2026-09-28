/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: NEXTFLOW_TEMPLATE — wire subworkflows and modules together
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK } from '../subworkflows/local/input_check/main'
include { HANDLE_DATA } from '../modules/local/handle_data/main'
include { EXAMPLE     } from '../modules/local/example/main'

workflow NEXTFLOW_TEMPLATE {

    take:
    samplesheet   // path: CSV samplesheet

    main:
    // 1. Parse + validate the samplesheet, grouping multi-file samples.
    INPUT_CHECK(samplesheet)

    // 2. Merge each sample's files into one FASTQ.
    HANDLE_DATA(INPUT_CHECK.out.reads)

    // 3. Example per-sample process (replace with your real stages).
    EXAMPLE(HANDLE_DATA.out.reads)

    // 4. Collate the versions every process publishes on the `versions` topic.
    //    Processes contribute to the topic implicitly, so no channel plumbing is
    //    needed when a stage is added.
    ch_versions = channel
        .topic('versions')
        .unique()
        .map { proc, tool, version -> "\"${proc}\":\n    ${tool}: ${version}\n" }
        .collectFile(name: 'collated_versions.yml', sort: true)

    emit:
    reads    = HANDLE_DATA.out.reads   // channel: [ val(meta), path(fastq) ]
    counts   = EXAMPLE.out.counts      // channel: [ val(meta), path(linecount) ]
    versions = ch_versions             // channel: path(collated_versions.yml)
}
