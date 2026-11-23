# local/sample

The `SAMPLE` scope: per-sample analysis of the prepared reads. It calls the
`EXAMPLE` step directly, with no stage between them, so its task is named
`SAMPLE:EXAMPLE` under the calling workflow. Replace `EXAMPLE` with real steps,
and give them stages under `subworkflows/local/sample/` as the analysis grows.

## Types

The script declares the type it produces, which callers include by name:

| Type         | Fields                       |
| ------------ | ---------------------------- |
| `LineCounts` | `id: String`, `counts: Path` |

## Inputs and outputs

| Direction | Name           | Type                  | Description                          |
| --------- | -------------- | --------------------- | ------------------------------------ |
| take      | `samples`      | `Channel<Sample>`     | One record per sample with its FASTQ |
| take      | `example_args` | `String`              | Extra wc options (`''` for none)     |
| emit      | `counts`       | `Channel<LineCounts>` | `id` and the `counts` file           |

## Usage

```nextflow
include { SAMPLE } from './subworkflows/local/sample/main'

counts = SAMPLE(samples, '')   // Channel<LineCounts>
```
