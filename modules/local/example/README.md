# local/example

Counts the lines in a sample's reads. It stands in for a real tool and shows the
conventions every module in this template follows: a destructured record input,
a record output keyed by `id`, a version on the `versions` topic, `ext.args` /
`ext.prefix` tuning and a stub block.

## Inputs and outputs

| Direction | Field    | Type     | Description                                      |
| --------- | -------- | -------- | ------------------------------------------------ |
| input     | `id`     | `String` | Sample identifier                                |
| input     | `fastq`  | `Path`   | Merged FASTQ of the sample, plain or gzipped     |
| output    | `id`     | `String` | Sample identifier                                |
| output    | `counts` | `Path`   | `<prefix>.linecount.txt`                         |
| topic     | —        | record   | `versions`: process, tool (`coreutils`), version |

## Usage

```nextflow
include { EXAMPLE } from './modules/local/example/main'

counts = EXAMPLE(samples)   // samples: Channel of records with id and fastq
```

```bash
nextflow module run ./modules/local/example/main.nf --id S1 --fastq reads.fastq.gz -with-docker
```

## Configuration

- `ext.args`: extra `wc` options.
- `ext.prefix`: output file prefix (default: `id`).
- Software: `quay.io/nf-core/ubuntu` or the conda spec in `environment.yml`.
