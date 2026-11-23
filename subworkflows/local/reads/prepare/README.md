# local/reads/prepare

The `PREPARE` stage of the `READS` scope: calls `HANDLE_DATA` on every sample and
replaces the sample's list of input FASTQs with the merged file, so each sample
leaves the stage as one `Sample` record.

## Types

The script declares the type it produces, which callers include by name:

| Type     | Fields                                            |
| -------- | ------------------------------------------------- |
| `Sample` | `id: String`, `platform: Platform`, `fastq: Path` |

## Inputs and outputs

| Direction | Name               | Type                   | Description                                 |
| --------- | ------------------ | ---------------------- | ------------------------------------------- |
| take      | `samples`          | `Channel<SampleReads>` | One record per sample with its input FASTQs |
| take      | `handle_data_args` | `String`               | Extra gzip options (`''` for none)          |
| emit      | `samples`          | `Channel<Sample>`      | `id`, `platform` and the merged `fastq`     |

## Usage

```nextflow
include { PREPARE ; Sample } from './subworkflows/local/reads/prepare/main'

prepared = PREPARE(samples, '')   // Channel<Sample>
```
