/*
 * Includes the template as a workflow, the way another pipeline composes it, and
 * passes the samplesheet as a channel of records instead of a file.
 */

nextflow.enable.types = true

include { workflow as LONGREAD } from '../../main.nf'

workflow {
    rows = channel.of(file("${projectDir}/../../assets/samplesheet.csv"))
        .flatMap { csv -> csv.splitCsv(header: true) }
        .map { row -> record(sample: row.sample, platform: row.platform, fastq: file("${projectDir}/../../${row.fastq}")) }

    longread = LONGREAD(record(input: rows))
    longread.reads.view { r -> "reads: ${r.sample}" }
    longread.versions.view { v -> "version: ${v.tool}" }
}
