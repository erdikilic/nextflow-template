/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: SEQUALI — read quality metrics for one sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Runs Sequali on a sample's merged FASTQ and writes an HTML report and the same
    metrics as JSON. Sequali detects the read format and compression itself and
    handles reads of any length, so one invocation covers ONT and PacBio input.
*/

nextflow.enable.types = true

process SEQUALI {
    tag id
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'biocontainers/sequali:1.0.2--py313h8c92656_1'

    input:
    record(
        id: String,
        fastq: Path
    )

    output:
    record(
        id: id,
        html: file('*.html'),
        json: file('*.json')
    )

    topic:
    record(process: task.process, tool: 'sequali', version: eval('sequali --version |& sed "1!d ; s/sequali //"')) >> 'versions'

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: id
    """
    sequali \\
        ${args} \\
        --threads ${task.cpus} \\
        --html ${prefix}.html \\
        --json ${prefix}.json \\
        ${fastq}
    """

    stub:
    def prefix = task.ext.prefix ?: id
    """
    touch ${prefix}.html
    echo '{}' > ${prefix}.json
    """
}
