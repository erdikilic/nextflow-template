# local/handle_data

Concatenates every FASTQ of a sample into one gzipped FASTQ. A long-read sample
often arrives as many files, such as an ONT barcode directory or a re-sequenced
PacBio run. `zcat -f` reads plain and gzipped files alike, so mixed inputs merge
cleanly. Each file is staged in its own numbered directory, so inputs that share
a file name do not collide.

## Inputs and outputs

| Direction | Field   | Type         | Description                                      |
| --------- | ------- | ------------ | ------------------------------------------------ |
| input     | `id`    | `String`     | Sample identifier                                |
| input     | `reads` | `List<Path>` | Every FASTQ of the sample, in merge order        |
| input     | `args`  | `String`     | Extra gzip options (`''` for none)               |
| output    | `id`    | `String`     | Sample identifier                                |
| output    | `fastq` | `Path`       | `<id>.merged.fastq.gz`                           |
| topic     | —       | record       | `versions`: process, tool (`coreutils`), version |

## Usage

```nextflow
include { HANDLE_DATA } from './modules/local/handle_data/main'

merged = HANDLE_DATA(samples, '')   // samples: Channel of records with id and reads
```

## Configuration

- `args` input: extra gzip options, e.g. `-6`; `''` for none. Outputs are
  named by `id`.
- Software: `quay.io/nf-core/ubuntu` or the conda spec in `environment.yml`.
