# local/input/check

The `CHECK` stage of the `INPUT` scope: checks long-read samplesheet rows and
groups them per sample. Loading the samplesheet into `SamplesheetRow` records has
already checked that every platform cell is empty or a `Platform` value and every
FASTQ exists. The `platform` column is optional: a missing column or an empty
cell loads as `null`, and `CHECK` gives that row the `platform` input
(`--platform`, default `ont_r10`). `CHECK` then adds the rules a type cannot
express and fails the run on the first violation:

- the `platform` input is `ont_r9`, `ont_r10` or `pacbio_hifi`;
- a sample name has no whitespace;
- a FASTQ ends with `.fastq`, `.fq`, `.fastq.gz` or `.fq.gz`;
- a sample listed on several rows always has the same platform.

Rows are grouped with `groupBy`, and each sample's FASTQs are sorted by file name.
The stage is channel logic only and runs no task.

## Types

The script declares the types it produces, which callers include by name:

| Type             | Fields                                                  |
| ---------------- | ------------------------------------------------------- |
| `Platform`       | enum: `ont_r9`, `ont_r10`, `pacbio_hifi`                |
| `SamplesheetRow` | `sample: String`, `platform: Platform?`, `fastq: Path`  |
| `SampleReads`    | `id: String`, `platform: Platform`, `reads: List<Path>` |

## Usage

```nextflow
include { CHECK ; SamplesheetRow } from './subworkflows/local/input/check/main'

params {
    input: Channel<SamplesheetRow>
    platform: String = 'ont_r10'
}

workflow {
    samples = CHECK(params.input, params.platform)   // Channel<SampleReads>
}
```
