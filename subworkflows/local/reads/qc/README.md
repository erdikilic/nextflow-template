# local/reads/qc

The `QC` stage of the `READS` scope: calls `SEQUALI` on every sample's merged
FASTQ and emits its HTML report and the same metrics as JSON, keyed by `id`.

## Types

The script declares the type it produces, which callers include by name:

| Type     | Fields                                   |
| -------- | ---------------------------------------- |
| `ReadQc` | `id: String`, `html: Path`, `json: Path` |

## Inputs and outputs

| Direction | Name           | Type              | Description                             |
| --------- | -------------- | ----------------- | --------------------------------------- |
| take      | `samples`      | `Channel<Sample>` | One record per sample with its FASTQ    |
| take      | `sequali_args` | `String`          | Extra Sequali options (`''` for none)   |
| emit      | `reports`      | `Channel<ReadQc>` | `id`, `html` and `json` Sequali reports |

## Usage

```nextflow
include { QC ; ReadQc } from './subworkflows/local/reads/qc/main'

reports = QC(samples, '--adapter-file adapters.fa')   // Channel<ReadQc>
```
