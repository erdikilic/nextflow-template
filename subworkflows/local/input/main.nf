/*
 * SCOPE: INPUT — turn the samplesheet into one record per sample
 *
 * Calls the CHECK stage, which checks the samplesheet rows and groups a sample's
 * FASTQs into one SampleReads record. Channel logic only; no task runs here.
 */

nextflow.enable.types = true

include { CHECK ; SamplesheetRow ; SampleReads } from './check/main'

workflow INPUT {
    take:
    rows: Channel<SamplesheetRow>
    platform: String // platform of a row whose platform cell is empty

    main:
    samples = CHECK(rows, platform)

    emit:
    samples: Channel<SampleReads>
}
