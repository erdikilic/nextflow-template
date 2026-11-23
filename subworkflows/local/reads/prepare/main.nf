/*
 * STAGE: READS:PREPARE — merge each sample's FASTQs into one file
 *
 * Calls HANDLE_DATA on every SampleReads record and replaces the sample's list
 * of input reads with the merged FASTQ, so each sample leaves the stage as one
 * Sample record.
 */

nextflow.enable.types = true

include { HANDLE_DATA } from '../../../../modules/local/handle_data/main'
include { Platform ; SampleReads } from '../../input/check/main'

workflow PREPARE {
    take:
    samples: Channel<SampleReads>
    handle_data_args: String // extra gzip options for HANDLE_DATA

    main:
    merged = HANDLE_DATA(samples, handle_data_args)
    prepared = merged
        .join(samples, by: 'id')
        .map { sample -> record(id: sample.id, platform: sample.platform, fastq: sample.fastq) }

    emit:
    samples: Channel<Sample> = prepared
}

// A sample with its reads merged into one FASTQ.
record Sample {
    id: String
    platform: Platform
    fastq: Path
}
