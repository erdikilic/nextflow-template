/*
 * SCOPE: SAMPLE — per-sample analysis of the prepared reads
 *
 * Calls EXAMPLE directly on every sample, a stand-in for the analysis steps of a
 * real workflow. A scope may call a step without a stage between them; add
 * stages under subworkflows/local/sample/ as the analysis grows.
 */

nextflow.enable.types = true

include { EXAMPLE } from '../../../modules/local/example/main'
include { Sample } from '../reads/prepare/main'

workflow SAMPLE {
    take:
    samples: Channel<Sample>
    example_args: String // extra wc options for EXAMPLE

    main:
    counts = EXAMPLE(samples, example_args)

    emit:
    counts: Channel<LineCounts>
}

// The EXAMPLE output of one sample.
record LineCounts {
    id: String
    counts: Path
}
