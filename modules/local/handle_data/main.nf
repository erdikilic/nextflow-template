/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS: HANDLE_DATA — normalise raw input into one FASTQ per sample
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A single sample often arrives as MANY FASTQs — e.g. an ONT barcode directory
    (`fastq_runid_*.fastq.gz`) or re-sequenced short-read lanes. HANDLE_DATA
    concatenates all of a sample's files into one stream (single-end / long read)
    or one pair (`_1`/`_2` for paired short reads). `zcat -f` accepts both plain
    and gzipped inputs, so mixed inputs merge cleanly.

    Input list order (from INPUT_CHECK): all R1s first, then all R2s.
*/

process HANDLE_DATA {
    tag "${meta.id}"
    label 'process_low'

    conda "conda-forge::coreutils=9.5"
    container 'nf-core/ubuntu:22.04'

    input:
    tuple val(meta), path(reads, stageAs: "input/*")

    output:
    tuple val(meta), path("*.merged.fastq.gz"), emit: reads
    path "versions.yml",                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def files = (reads instanceof List ? reads : [reads]).collect { f -> f.toString() }
    if (meta.single_end) {
        """
        zcat -f ${files.join(' ')} | gzip -c > ${prefix}.merged.fastq.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            coreutils: \$(wc --version | head -n1 | sed 's/^.* //')
        END_VERSIONS
        """
    } else {
        def half = files.size().intdiv(2)
        def r1 = files[0..<half].join(' ')
        def r2 = files[half..-1].join(' ')
        """
        zcat -f ${r1} | gzip -c > ${prefix}_1.merged.fastq.gz
        zcat -f ${r2} | gzip -c > ${prefix}_2.merged.fastq.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            coreutils: \$(wc --version | head -n1 | sed 's/^.* //')
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def out = meta.single_end ? "${prefix}.merged.fastq.gz" : "${prefix}_1.merged.fastq.gz ${prefix}_2.merged.fastq.gz"
    """
    for f in ${out}; do echo | gzip -c > \$f; done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coreutils: 9.5
    END_VERSIONS
    """
}
