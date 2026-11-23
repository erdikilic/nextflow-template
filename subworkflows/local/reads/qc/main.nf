/*
 * STAGE: READS:QC — read quality metrics for each sample
 *
 * Calls SEQUALI on every sample's merged FASTQ and emits its HTML and JSON
 * reports as one record per sample, keyed by `id`.
 */

nextflow.enable.types = true

include { SEQUALI } from '../../../../modules/local/sequali/main'
include { Sample } from '../prepare/main'

workflow QC {
    take:
    samples: Channel<Sample>
    sequali_args: String // extra Sequali options

    main:
    reports = SEQUALI(samples, sequali_args)

    emit:
    reports: Channel<ReadQc>
}

// The read-QC reports of one sample.
record ReadQc {
    id: String
    html: Path
    json: Path
}
