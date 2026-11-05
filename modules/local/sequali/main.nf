/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: SEQUALI — read quality metrics for one sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Runs Sequali on a sample's merged FASTQ and writes an HTML report and the same
    metrics as JSON. Sequali detects the read format and compression itself and
    handles reads of any length, so one invocation covers ONT and PacBio input.
*/

process SEQUALI {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'biocontainers/sequali:1.0.2--py313h8c92656_1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), path("*.json"), emit: report
    tuple val("${task.process}"), val('sequali'), eval('sequali --version |& sed "1!d ; s/sequali //"'), emit: versions_sequali, topic: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    sequali \\
        ${args} \\
        --threads ${task.cpus} \\
        --html ${prefix}.html \\
        --json ${prefix}.json \\
        ${reads}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.html
    echo '{}' > ${prefix}.json
    """
}
