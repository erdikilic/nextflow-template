/*
 * Includes the template together with its params block, the way a pipeline that
 * exposes the template's parameters composes it: --longread.<name> sets any
 * parameter of the included pipeline.
 */

nextflow.enable.types = true

include { params as LongreadParams ; workflow as LONGREAD } from '../../main.nf'

params {
    // Parameters of the included pipeline, each given as --longread.<name>.
    longread: LongreadParams
}

workflow {
    longread = LONGREAD(params.longread)
    longread.reads.view { r -> "reads: ${r.sample}" }
    longread.versions.view { v -> "version: ${v.tool}" }
}
