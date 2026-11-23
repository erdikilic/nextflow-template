/*
 * SCOPE: READS — prepare each sample's reads and check their quality
 *
 * Calls the PREPARE stage, which merges a sample's FASTQs into one file, then
 * the QC stage on the merged reads. Emits the prepared samples and their QC
 * reports, both keyed by `id`.
 */

nextflow.enable.types = true

include { SampleReads } from '../input/check/main'
include { PREPARE ; Sample } from './prepare/main'
include { QC ; ReadQc } from './qc/main'

workflow READS {
    take:
    samples: Channel<SampleReads>
    handle_data_args: String // extra gzip options for HANDLE_DATA
    sequali_args: String // extra Sequali options

    main:
    prepared = PREPARE(samples, handle_data_args)
    reports = QC(prepared, sequali_args)

    emit:
    samples: Channel<Sample> = prepared
    qc: Channel<ReadQc> = reports
}
