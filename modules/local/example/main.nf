/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: EXAMPLE — placeholder per-sample process
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Counts the lines in each read file (a stand-in for a real tool). Demonstrates
    the conventions every module should follow: a `meta` map, `ext.args`/`ext.prefix`
    from conf/modules, a container + conda spec, a `versions.yml` emission, and a
    matching stub block so `-stub` runs without the tool installed.
*/

process EXAMPLE {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::coreutils=9.5"
    container 'nf-core/ubuntu:22.04'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.linecount.txt"), emit: counts
    path "versions.yml",                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    zcat -f ${reads} | wc -l ${args} > ${prefix}.linecount.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: \$(wc --version | head -n1 | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo 0 > ${prefix}.linecount.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: 9.5
    END_VERSIONS
    """
}
