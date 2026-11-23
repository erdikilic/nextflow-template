/*
 * STAGE: INPUT:CHECK — check samplesheet rows and group them per sample
 *
 * Takes the samplesheet as a channel of SamplesheetRow records and the
 * --platform value. Loading the samplesheet into that type has already checked
 * that every platform cell is empty or a Platform value and every FASTQ exists.
 * CHECK gives a row with no platform the --platform value, fails on a
 * --platform outside Platform, and adds the rules a type cannot express (sample
 * names without whitespace, FASTQ file extensions, one platform per sample). It
 * is channel logic only and runs no task.
 *
 * Rows are then grouped by sample, so a sample provided as many files (e.g. an
 * ONT barcode directory split across several FASTQs, or a re-sequenced PacBio
 * run) becomes one SampleReads record. READS:PREPARE then concatenates them.
 * The reads of a sample are sorted by file name for reproducibility.
 */

nextflow.enable.types = true

workflow CHECK {
    take:
    rows: Channel<SamplesheetRow>
    platform: String // platform of a row whose platform cell is empty

    main:
    // Every Platform value; the type checker offers no Platform.values().
    def known = [Platform.ont_r9, Platform.ont_r10, Platform.pacbio_hifi]
    def fallback = known.find { p -> p.name() == platform }
    if (fallback == null) {
        error("--platform '${platform}' must be one of: ${known.collect { p -> p.name() }.join(', ')}")
    }

    samples = rows
        .map { row ->
            if (!(row.sample ==~ /^\S+$/)) {
                error("Samplesheet: sample name '${row.sample}' must not be empty or contain whitespace")
            }
            if (!(row.fastq.name ==~ /^.+\.f(ast)?q(\.gz)?$/)) {
                error("Samplesheet: '${row.fastq}' of sample '${row.sample}' must end with .fastq, .fq, .fastq.gz or .fq.gz")
            }
            def resolved = row.platform
            if (resolved == null) {
                resolved = fallback
            }
            tuple(row.sample, record(platform: resolved, fastq: row.fastq))
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

// Sequencing platform of a sample: Oxford Nanopore R9 or R10 chemistry, or
// PacBio HiFi. Converting a samplesheet value outside this list fails the run
// before any task starts.
enum Platform {
    ont_r9,
    ont_r10,
    pacbio_hifi,
}

// One samplesheet row: a single FASTQ of a sample. The field names match the
// samplesheet columns, so this record type is the samplesheet schema. The
// platform column is optional: a missing column or an empty cell loads as null
// and takes the --platform value in CHECK.
record SamplesheetRow {
    sample: String
    platform: Platform?
    fastq: Path
}

// A sample with every FASTQ it arrived as, sorted by file name.
record SampleReads {
    id: String
    platform: Platform
    reads: List<Path>
}
