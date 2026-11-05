/*
 * PROCESS: SEQUALI — read quality metrics for one sample
 *
 * Runs Sequali on a sample's merged FASTQ and writes an HTML report and the same
 * metrics as JSON. Sequali detects the read format and compression itself and
 * handles reads of any length, so one invocation covers ONT and PacBio input.
 */

nextflow.enable.types = true

process SEQUALI {
    tag id
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/sequali:1.0.2--py313h8c92656_1'

    input:
    record(
        id: String,
        fastq: Path
    )
    // Extra Sequali options, e.g. --adapter-file adapters.fa.
    args: String

    output:
    record(
        id: id,
        html: file('*.html'),
        json: file('*.json'),
    )

    topic:
    record(process: task.process, tool: 'sequali', version: eval('sequali --version |& sed "1!d ; s/sequali //"')) >> 'versions'

    script:
    """
    sequali \\
        ${args} \\
        --threads ${task.cpus} \\
        --html ${id}.html \\
        --json ${id}.json \\
        ${fastq}
    """

    stub:
    """
    touch ${id}.html
    echo '{}' > ${id}.json
    """
}
