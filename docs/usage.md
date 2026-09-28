# Usage

## Input: samplesheet

Provide a CSV via `--input`. The workflow takes long-read data only — Oxford
Nanopore and PacBio. Columns:

| Column     | Description                                            |
| ---------- | ------------------------------------------------------ |
| `sample`   | Sample name (no spaces). Becomes `meta.id`.            |
| `platform` | `nanopore` or `pacbio`. Becomes `meta.platform`.       |
| `fastq`    | One long-read FASTQ. `.fastq`/`.fq`, optionally `.gz`. |

A sample that arrives as several files — an ONT barcode directory split across
many FASTQs, or a re-sequenced run — gets **one row per file**, all sharing the
same `sample` name. `INPUT_CHECK` groups those rows and `HANDLE_DATA` merges them
into a single FASTQ per sample.

```csv
sample,platform,fastq
NANOPORE_BARCODE01,nanopore,/data/barcode01/fastq_runid_a.fastq.gz
NANOPORE_BARCODE01,nanopore,/data/barcode01/fastq_runid_b.fastq.gz
PACBIO_HIFI,pacbio,/data/pacbio/hifi_reads.fastq.gz
```

The samplesheet is validated against [`assets/schema_input.json`](../assets/schema_input.json)
by the `nf-schema` plugin. `meta` carries `id` and `platform`, so modules can branch
on the technology (e.g. `minimap2 -x map-ont` vs `-x map-hifi`).

## Running

```bash
nextflow run . --input samplesheet.csv --outdir results -profile docker
```

`-profile` selects the container engine and (optionally) a hardware tier and test
data — e.g. `-profile apptainer,server` or `-profile test,docker`. See
[`README.md`](../README.md#profiles).

## Key parameters

| Parameter            | Default   | Description                |
| -------------------- | --------- | -------------------------- |
| `--input`            | _(req.)_  | Samplesheet CSV.           |
| `--outdir`           | `results` | Output directory.          |
| `--max_cpus`         | `14`      | Per-task CPU limit.        |
| `--max_memory`       | `30.GB`   | Per-task memory limit.     |
| `--publish_dir_mode` | `copy`    | How results are published. |

`nextflow run . --help` lists the parameters from `nextflow_schema.json`.
`--help <parameter>` shows one parameter in full, and `--help_full --show_hidden`
lists every parameter, hidden ones included. Parameters are checked against the
schema before the run starts; `--validate_params false` skips the check.

## Resource limits

`--max_cpus` and `--max_memory` feed `process.resourceLimits`: no single task may
use more, and Nextflow lowers any larger request to the limit, including the
memory increase on a retry. A hardware tier (`laptop`, `workstation`, `server`,
`hpc`) sets both for its host class; values given on the command line take
precedence over the tier.

```bash
nextflow run . -profile docker,server --max_cpus 48 --max_memory 180.GB ...
```

Each task requests the CPUs and memory of its label in
[`conf/base.config`](../conf/base.config) (`process_low` = 4 CPUs, 8 GB, and so
on); the limits only cap those requests. A larger host therefore runs more tasks
at once rather than larger tasks. To give a heavy tool more of a big machine,
raise its label, or override one process in a custom config passed with `-c`:

```groovy
process {
    withName: EXAMPLE {
        cpus   = 32
        memory = 128.GB
    }
}
```
