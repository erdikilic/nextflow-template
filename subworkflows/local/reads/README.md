# local/reads

The `READS` scope: prepares each sample's reads and checks their quality. It
calls two stages, so its tasks are named `READS:PREPARE:HANDLE_DATA` and
`READS:QC:SEQUALI` under the calling workflow:

- [`PREPARE`](prepare/README.md) merges a sample's FASTQs into one file;
- [`QC`](qc/README.md) runs Sequali on the merged reads.

## Inputs and outputs

| Direction | Name               | Type                   | Description                                 |
| --------- | ------------------ | ---------------------- | ------------------------------------------- |
| take      | `samples`          | `Channel<SampleReads>` | One record per sample with its input FASTQs |
| take      | `handle_data_args` | `String`               | Extra gzip options (`''` for none)          |
| take      | `sequali_args`     | `String`               | Extra Sequali options (`''` for none)       |
| emit      | `samples`          | `Channel<Sample>`      | `id`, `platform` and the merged `fastq`     |
| emit      | `qc`               | `Channel<ReadQc>`      | `id`, `html` and `json` Sequali reports     |

## Usage

```nextflow
include { READS } from './subworkflows/local/reads/main'

reads = READS(samples, '', '')
reads.samples   // Channel<Sample>
reads.qc        // Channel<ReadQc>
```
