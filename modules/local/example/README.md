# local/example

Counts the lines in a sample's reads. It stands in for a real tool and shows the
conventions every module in this template follows: a destructured record input,
tool options as a typed `args` input, a record output keyed by `id`, a version on
the `versions` topic and a stub block.

## Inputs and outputs

| Direction | Field    | Type     | Description                                      |
| --------- | -------- | -------- | ------------------------------------------------ |
| input     | `id`     | `String` | Sample identifier                                |
| input     | `fastq`  | `Path`   | Merged FASTQ of the sample, plain or gzipped     |
| input     | `args`   | `String` | Extra wc options (`''` for none)                 |
| output    | `id`     | `String` | Sample identifier                                |
| output    | `counts` | `Path`   | `<id>.linecount.txt`                             |
| topic     | —        | record   | `versions`: process, tool (`coreutils`), version |

## Usage

```nextflow
include { EXAMPLE } from './modules/local/example/main'

counts = EXAMPLE(samples, '')   // samples: Channel of records with id and fastq
```

```bash
nextflow module run ./modules/local/example/main.nf --id S1 --fastq reads.fastq.gz --args= -with-docker
```

## Configuration

- `args` input: extra wc options, e.g. `--bytes`; `''` for none. Outputs are
  named by `id`.
- Software: `quay.io/nf-core/ubuntu` or the conda spec in `environment.yml`.
