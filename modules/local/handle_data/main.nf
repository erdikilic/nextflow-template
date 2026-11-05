/*
 * PROCESS: HANDLE_DATA — normalise raw input into one FASTQ per sample
 *
 * A single long-read sample often arrives as MANY FASTQs — an ONT barcode
 * directory (`fastq_runid_*.fastq.gz`) or a re-sequenced PacBio run. HANDLE_DATA
 * concatenates all of a sample's files into one gzipped FASTQ. `zcat -f` accepts
 * both plain and gzipped inputs, so mixed inputs merge cleanly.
 *
 * Each file is staged into its own numbered directory (`stageAs reads, '?/*'`) so
 * inputs that share a basename across run directories do not collide.
 */

nextflow.enable.types = true

process HANDLE_DATA {
    tag id
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/nf-core/ubuntu:22.04'

    input:
    record(
        id: String,
        reads: List<Path>
    )
    // Extra gzip options, e.g. -6.
    args: String

    stage:
    stageAs reads, '?/*'

    output:
    record(
        id: id,
        fastq: file('*.merged.fastq.gz'),
    )

    topic:
    record(process: task.process, tool: 'coreutils', version: eval('wc --version | head -n1 | sed "s/^.* //"')) >> 'versions'

    script:
    """
    zcat -f ${reads.join(' ')} | gzip -c ${args} > ${id}.merged.fastq.gz
    """

    stub:
    """
    echo | gzip -c > ${id}.merged.fastq.gz
    """
}
