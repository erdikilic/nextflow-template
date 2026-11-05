# local/sequali

Runs [Sequali](https://github.com/rhpvorderman/sequali) on the merged FASTQ of one
sample and writes an HTML report and the same metrics as JSON. Sequali detects the
read format and compression itself and handles reads of any length, so one
invocation covers Oxford Nanopore and PacBio input.

## Inputs and outputs

| Direction | Field   | Type     | Description                                    |
| --------- | ------- | -------- | ---------------------------------------------- |
| input     | `id`    | `String` | Sample identifier                              |
| input     | `fastq` | `Path`   | Merged FASTQ of the sample, plain or gzipped   |
| input     | `args`  | `String` | Extra Sequali options (`''` for none)          |
| output    | `id`    | `String` | Sample identifier                              |
| output    | `html`  | `Path`   | `<id>.html`, the Sequali report                |
| output    | `json`  | `Path`   | `<id>.json`, the report's metrics              |
| topic     | —       | record   | `versions`: process, tool (`sequali`), version |

## Usage

```nextflow
include { SEQUALI } from './modules/local/sequali/main'

qc = SEQUALI(samples, '')   // samples: Channel of records with id and fastq
```

Run it on its own:

```bash
nextflow module run ./modules/local/sequali/main.nf --id S1 --fastq reads.fastq.gz --args= -with-docker
```

## Configuration

- `args` input: extra Sequali options, e.g. `--adapter-file adapters.fa`; `''` for none. Outputs are
  named by `id`.
- Software: `quay.io/biocontainers/sequali` or the conda spec in `environment.yml`.
