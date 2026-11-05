# local/input_check

Checks long-read samplesheet rows and groups them per sample. Loading the
samplesheet into `SamplesheetRow` records has already checked that every platform
is a `Platform` value and every FASTQ exists; `INPUT_CHECK` adds the rules a type
cannot express and fails the run on the first violation:

- a sample name has no whitespace;
- a FASTQ ends with `.fastq`, `.fq`, `.fastq.gz` or `.fq.gz`;
- a sample listed on several rows always has the same platform.

Rows are grouped with `groupBy`, and each sample's FASTQs are sorted by file name.

## Types

The script declares the types it produces, which callers include by name:

| Type             | Fields                                                  |
| ---------------- | ------------------------------------------------------- |
| `Platform`       | enum: `nanopore`, `pacbio`                              |
| `SamplesheetRow` | `sample: String`, `platform: Platform`, `fastq: Path`   |
| `SampleReads`    | `id: String`, `platform: Platform`, `reads: List<Path>` |

## Usage

```nextflow
include { INPUT_CHECK ; SamplesheetRow } from './subworkflows/local/input_check/main'

params {
    input: Channel<SamplesheetRow>
}

workflow {
    samples = INPUT_CHECK(params.input)   // Channel<SampleReads>
}
```
