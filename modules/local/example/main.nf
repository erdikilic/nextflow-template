/*
 * PROCESS: EXAMPLE — placeholder per-sample process
 *
 * Counts the lines in each read file (a stand-in for a real tool). Demonstrates
 * the conventions every module follows: a destructured record input naming only
 * the fields the process reads, a record output keyed by `id`, `ext.args` /
 * `ext.prefix` from conf/modules, a container plus an `environment.yml` conda
 * spec, a version emitted to the `versions` topic, and a matching stub block.
 */

nextflow.enable.types = true

process EXAMPLE {
    tag id
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'nf-core/ubuntu:22.04'

    input:
    record(
        id: String,
        fastq: Path
    )

    output:
    record(
        id: id,
        counts: file('*.linecount.txt'),
    )

    topic:
    record(process: task.process, tool: 'coreutils', version: eval('wc --version | head -n1 | sed "s/^.* //"')) >> 'versions'

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: id
    """
    zcat -f ${fastq} | wc -l ${args} > ${prefix}.linecount.txt
    """

    stub:
    def prefix = task.ext.prefix ?: id
    """
    echo 0 > ${prefix}.linecount.txt
    """
}
