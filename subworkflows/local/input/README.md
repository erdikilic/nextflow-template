# local/input

The `INPUT` scope: turns the samplesheet into one `SampleReads` record per sample.
It calls one stage, [`CHECK`](check/README.md), which gives a row with no
platform the `--platform` value, checks the rows and groups a sample's FASTQs.
The scope is channel logic only and runs no task.

## Inputs and outputs

| Direction | Name       | Type                      | Description                                    |
| --------- | ---------- | ------------------------- | ---------------------------------------------- |
| take      | `rows`     | `Channel<SamplesheetRow>` | One record per samplesheet row                 |
| take      | `platform` | `String`                  | Platform of a row whose platform cell is empty |
| emit      | `samples`  | `Channel<SampleReads>`    | One record per sample, FASTQs sorted by name   |

## Usage

```nextflow
include { INPUT } from './subworkflows/local/input/main'

samples = INPUT(params.input, params.platform)   // Channel<SampleReads>
```
