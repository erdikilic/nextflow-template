/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: NEXTFLOW_TEMPLATE — wire subworkflows and modules together
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Every module takes the fields it needs from a sample record and returns a
    record keyed by `id`. The workflow joins those records back by `id`, so one
    channel carries every result of a sample.
*/

nextflow.enable.types = true

include { INPUT_CHECK ; Platform ; SamplesheetRow } from '../subworkflows/local/input_check/main'
include { HANDLE_DATA                            } from '../modules/local/handle_data/main'
include { SEQUALI                                } from '../modules/local/sequali/main'
include { EXAMPLE                                } from '../modules/local/example/main'

workflow NEXTFLOW_TEMPLATE {

    take:
    rows: Channel<SamplesheetRow>

    main:
    // 1. Check the samplesheet rows and group multi-file samples.
    samples = INPUT_CHECK(rows)

    // 2. Merge each sample's files into one FASTQ. The merged file replaces the
    //    list of input reads in the sample record.
    merged = HANDLE_DATA(samples)
    reads = samples
        .join(merged, by: 'id')
        .map { sample -> record(id: sample.id, platform: sample.platform, fastq: sample.fastq) }

    // 3. Read QC on each merged FASTQ.
    qc = SEQUALI(reads)

    // 4. Example per-sample process (replace with your real stages).
    counts = EXAMPLE(reads)

    // 5. One record per sample with every result.
    results = reads
        .join(qc, by: 'id')
        .join(counts, by: 'id')

    emit:
    results: Channel<SampleResult>
}

// A sample with its reads merged into one FASTQ.
record Sample {
    id: String
    platform: Platform
    fastq: Path
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
