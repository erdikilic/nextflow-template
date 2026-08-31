/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: PIPELINE — wire subworkflows and modules together
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK } from '../subworkflows/local/input_check/main'
include { HANDLE_DATA } from '../modules/local/handle_data/main'
include { EXAMPLE     } from '../modules/local/example/main'

workflow PIPELINE {

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
    channel
        .topic('versions')
        .unique()
        .map { proc, tool, version -> "\"${proc}\":\n    ${tool}: ${version}\n" }
        .collectFile(name: 'collated_versions.yml', storeDir: "${params.outdir}/pipeline_info", sort: true)

    emit:
    reads  = HANDLE_DATA.out.reads
    counts = EXAMPLE.out.counts
}
