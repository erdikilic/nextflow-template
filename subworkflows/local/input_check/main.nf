/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: INPUT_CHECK — read + validate the samplesheet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Validates the samplesheet against assets/schema_input.json (nf-schema), then
    GROUPS rows by sample so a sample provided as many files (e.g. an ONT barcode
    directory split across several FASTQs, or a re-sequenced PacBio run) becomes a
    single entry. HANDLE_DATA then concatenates them.

    The samplesheet path is supplied by the caller through `take:`, which keeps the
    subworkflow reusable and testable in isolation.

    Emits [ val(meta), [ reads ] ], reads sorted by filename for reproducibility.
    meta carries id and platform (nanopore/pacbio) so downstream modules can branch
    (e.g. minimap2 -x map-ont vs -x map-hifi).
*/

include { samplesheetToList } from 'plugin/nf-schema'

workflow INPUT_CHECK {

    take:
    samplesheet   // path: CSV samplesheet

    // channel: [ val(meta), [ path(reads) ] ]
    emit:
    channel
        .fromList(samplesheetToList(samplesheet, "${projectDir}/assets/schema_input.json"))
        .map { meta, fastq ->
            // Rebuild meta explicitly so the grouping key stays stable when
            // extra samplesheet columns are added.
            [[id: meta.id, platform: meta.platform], fastq]
        }
        .groupTuple()
        .map { meta, fastqs ->
            [meta, fastqs.toSorted { f -> f.name }]
        }
}
