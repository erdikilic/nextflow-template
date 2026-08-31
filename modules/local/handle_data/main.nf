/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: HANDLE_DATA — normalise raw input into one FASTQ per sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A single long-read sample often arrives as MANY FASTQs — an ONT barcode
    directory (`fastq_runid_*.fastq.gz`) or a re-sequenced PacBio run. HANDLE_DATA
    concatenates all of a sample's files into one gzipped FASTQ. `zcat -f` accepts
    both plain and gzipped inputs, so mixed inputs merge cleanly.

    Each file is staged into its own numbered directory (`stageAs: '?/*'`) so
    inputs that share a basename across run directories do not collide.
*/

process HANDLE_DATA {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'nf-core/ubuntu:22.04'

    input:
    tuple val(meta), path(reads, stageAs: '?/*')

    output:
    tuple val(meta), path("*.merged.fastq.gz"), emit: reads
    tuple val("${task.process}"), val('coreutils'), eval('wc --version | head -n1 | sed "s/^.* //"'), emit: versions_coreutils, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat -f ${reads} | gzip -c ${args} > ${prefix}.merged.fastq.gz
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip -c > ${prefix}.merged.fastq.gz
    """
}
