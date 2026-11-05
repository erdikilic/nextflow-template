/*
 * PROCESS: EXAMPLE — placeholder per-sample process
 *
 * Counts the lines in each read file (a stand-in for a real tool). Demonstrates
 * the conventions every module follows: a destructured record input naming only
 * the fields the process reads, tool options as a typed `args` input, a record
 * output keyed by `id`, a container plus an `environment.yml` conda
 * spec, a version emitted to the `versions` topic, and a matching stub block.
 */

nextflow.enable.types = true

process EXAMPLE {
    tag id
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/nf-core/ubuntu:22.04'

    input:
    record(
        id: String,
        fastq: Path
    )
    // Extra wc options.
    args: String

    output:
    record(
        id: id,
        counts: file('*.linecount.txt'),
    )

    topic:
    record(process: task.process, tool: 'coreutils', version: eval('wc --version | head -n1 | sed "s/^.* //"')) >> 'versions'

    script:
    """
    zcat -f ${fastq} | wc -l ${args} > ${id}.linecount.txt
    """

    stub:
    """
    echo 0 > ${id}.linecount.txt
    """
}
