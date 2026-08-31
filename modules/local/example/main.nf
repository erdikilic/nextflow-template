/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: EXAMPLE — placeholder per-sample process
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Counts the lines in each read file (a stand-in for a real tool). Demonstrates
    the conventions every module follows: a `meta` map, `ext.args`/`ext.prefix`
    from conf/modules, a container plus an `environment.yml` conda spec, a version
    published on the `versions` topic, and a matching stub block.
*/

process EXAMPLE {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'nf-core/ubuntu:22.04'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.linecount.txt"), emit: counts
    tuple val("${task.process}"), val('coreutils'), eval('wc --version | head -n1 | sed "s/^.* //"'), emit: versions_coreutils, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat -f ${reads} | wc -l ${args} > ${prefix}.linecount.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo 0 > ${prefix}.linecount.txt
    """
}
