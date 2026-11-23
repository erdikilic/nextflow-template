/*
 * WORKFLOW: NEXTFLOW_TEMPLATE — call the scopes in order
 *
 * The workflow calls three scopes: INPUT checks the samplesheet, READS prepares
 * each sample's reads and checks their quality, SAMPLE analyses them. A scope
 * calls stages and a stage calls steps, so every task is named by its call path,
 * for example NEXTFLOW_TEMPLATE:READS:QC:SEQUALI.
 *
 * Every step takes the fields it needs from a sample record and returns a record
 * keyed by `id`. The workflow joins those records back by `id`, so one channel
 * carries every result of a sample.
 */

nextflow.enable.types = true

include { INPUT } from '../subworkflows/local/input/main'
include { Platform ; SamplesheetRow } from '../subworkflows/local/input/check/main'
include { READS } from '../subworkflows/local/reads/main'
include { SAMPLE } from '../subworkflows/local/sample/main'

workflow NEXTFLOW_TEMPLATE {
    take:
    rows: Channel<SamplesheetRow>
    platform: String // platform of a row whose platform cell is empty
    handle_data_args: String // extra gzip options for HANDLE_DATA
    sequali_args: String // extra Sequali options
    example_args: String // extra wc options for EXAMPLE

    main:
    // 1. Check the samplesheet rows and group multi-file samples.
    samples = INPUT(rows, platform)

    // 2. Merge each sample's files into one FASTQ and check its quality.
    reads = READS(samples, handle_data_args, sequali_args)

    // 3. Per-sample analysis (replace with your real stages).
    counts = SAMPLE(reads.samples, example_args)

    // 4. One record per sample with every result.
    results = reads.samples
        .join(reads.qc, by: 'id')
        .join(counts, by: 'id')

    emit:
    results: Channel<SampleResult>
}

// Every result the workflow produces for one sample.
record SampleResult {
    id: String
    platform: Platform
    fastq: Path
    html: Path
    json: Path
    counts: Path
}
