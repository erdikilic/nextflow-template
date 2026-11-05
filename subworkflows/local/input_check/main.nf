/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: INPUT_CHECK — check samplesheet rows and group them per sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Takes the samplesheet as a channel of SamplesheetRow records. Loading the
    samplesheet into that type has already checked that every platform is a
    Platform value and every FASTQ exists; INPUT_CHECK adds the rules a type
    cannot express (sample names without whitespace, FASTQ file extensions, one
    platform per sample).

    Rows are then GROUPED by sample, so a sample provided as many files (e.g. an
    ONT barcode directory split across several FASTQs, or a re-sequenced PacBio
    run) becomes one SampleReads record. HANDLE_DATA then concatenates them.
    The reads of a sample are sorted by file name for reproducibility.
*/

nextflow.enable.types = true

workflow INPUT_CHECK {

    take:
    rows: Channel<SamplesheetRow>

    main:
    samples = rows
        .map { row ->
            if (!(row.sample ==~ /^\S+$/)) {
                error("Samplesheet: sample name '${row.sample}' must not be empty or contain whitespace")
            }
            if (!(row.fastq.name ==~ /^.+\.f(ast)?q(\.gz)?$/)) {
                error("Samplesheet: '${row.fastq}' of sample '${row.sample}' must end with .fastq, .fq, .fastq.gz or .fq.gz")
            }
            tuple(row.sample, row)
        }
        .groupBy()
        .map { id, group ->
            def platforms = group.collect { row -> row.platform }.toSet()
            if (platforms.size() != 1) {
                error("Samplesheet: sample '${id}' is listed with more than one platform: ${platforms.join(', ')}")
            }
            record(
                id: id,
                platform: platforms.toList().first(),
                reads: group.collect { row -> row.fastq }.toSorted { fastq -> fastq.name },
            )
        }

    emit:
    samples: Channel<SampleReads>
}

// Sequencing platform of a sample. Converting a samplesheet value outside this
// list fails the run before any task starts.
enum Platform {
    nanopore,
    pacbio
}

// One samplesheet row: a single FASTQ of a sample. The field names match the
// samplesheet columns, so this record type is the samplesheet schema.
record SamplesheetRow {
    sample: String
    platform: Platform
    fastq: Path
}

// A sample with every FASTQ it arrived as, sorted by file name.
record SampleReads {
    id: String
    platform: Platform
    reads: List<Path>
}
