/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: INPUT_CHECK — read + validate the samplesheet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Validates the samplesheet against assets/schema_input.json (nf-schema), then
    GROUPS rows by sample so a sample provided as many files (e.g. an ONT barcode
    directory split across several FASTQs, or re-sequenced short-read lanes)
    becomes a single entry. HANDLE_DATA then concatenates them.

    Emits [ val(meta), [ reads ] ] where the read list is all R1s followed by all
    R2s. meta carries id, platform, single_end, long_reads so downstream modules
    can branch (e.g. minimap2 -x map-ont for long reads vs -x sr for short reads).
*/

include { samplesheetToList } from 'plugin/nf-schema'

workflow INPUT_CHECK {

    main:
    ch_reads = channel
        .fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { meta, fastq_1, fastq_2 ->
            def key = [
                id:          meta.id,
                platform:    meta.platform,
                single_end:  !fastq_2,
                long_reads:  meta.platform in ['nanopore', 'pacbio'],
            ]
            [key, fastq_1, fastq_2]
        }
        .groupTuple()
        .map { meta, r1, r2 ->
            def reads = r1.findAll { f -> f } + r2.findAll { f -> f }
            [meta, reads.collect { f -> file(f) }]
        }

    emit:
    reads = ch_reads   // channel: [ val(meta), [ path(reads) ] ]
}
