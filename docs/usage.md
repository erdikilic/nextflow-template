# Usage

## Input: samplesheet

Provide a CSV via `--input`. The workflow takes long-read data only — Oxford
Nanopore and PacBio. Columns:

| Column     | Description                                            |
| ---------- | ------------------------------------------------------ |
| `sample`   | Sample name (no spaces). Becomes the record's `id`.    |
| `platform` | `nanopore` or `pacbio`.                                |
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

Nextflow loads the samplesheet into `SamplesheetRow` records
([`INPUT_CHECK`](../subworkflows/local/input_check/main.nf)) before the run starts: a `platform`
outside the list or a FASTQ that does not exist fails the run at once.
`INPUT_CHECK` then rejects sample names with whitespace, files without a FASTQ
extension, and a sample listed with two platforms. Relative FASTQ paths resolve
against the launch directory. Each sample record carries `id` and `platform`, so a
stage can branch on the technology (e.g. `minimap2 -x map-ont` vs `-x map-hifi`).

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
| `--handle_data_args` | _(empty)_ | Extra `gzip` options.      |
| `--sequali_args`     | _(empty)_ | Extra Sequali options.     |
| `--example_args`     | _(empty)_ | Extra `wc` options.        |

A tool option that starts with a dash is given with `=`, so it is not read as a
separate parameter: `--sequali_args='--adapter-file adapters.fa'`.

`nextflow run . --help` lists the parameters from `nextflow_schema.json`.
`--help <parameter>` shows one parameter in full, and `--help_full --show_hidden`
lists every parameter, hidden ones included. Nextflow converts every parameter to
its declared type and stops on a parameter that is not declared, so a misspelt
option fails before the run starts.

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

## Resuming and caching

`-resume` reuses every task whose inputs, script and container are unchanged,
using the task cache in `.nextflow/cache` under the launch directory:

```bash
nextflow run . -profile docker --input samplesheet.csv -resume
```

The workflow keeps its tasks reproducible for the cache: a sample's FASTQs are
sorted by file name before they are merged, and the versions index is sorted.

- **Cloud cache** — on a cloud VM, where the launch directory disappears with the
  VM, keep the cache in object storage. Set the variables, name each run, and
  resume by session ID:

  ```bash
  export NXF_CLOUDCACHE_PATH=s3://my-bucket/cache
  export NXF_IGNORE_RESUME_HISTORY=true
  nextflow run . -profile docker --input samplesheet.csv -name run-1
  nextflow run . -profile docker --input samplesheet.csv -name run-2 -resume <session-id>
  ```

- **Global cache** — Seqera Platform (with Nextflow 26.10 or later) can keep one
  content-addressed cache for an organisation in AWS, Google Cloud or Azure
  storage and reuse identical tasks across runs and pipelines, not only across
  resumes of one run. It is a Platform feature, so the workflow needs no
  change to use it.

## Data lineage

Lineage is enabled in `nextflow.config`, so every run records its parameters,
tasks and published files in `.lineage/` under the launch directory. Each output
target carries a label (`reads`, `qc`, `example`, `provenance`).

```bash
nextflow lineage list                                   # runs and their lineage IDs
nextflow lineage view lid://<run-id>                    # parameters, config, metadata
nextflow lineage find type=FileOutput labels=qc         # every QC report
nextflow lineage check lid://<run-id>/reads/samplesheet.csv   # verify a checksum
nextflow lineage render lid://<run-id>/qc/sequali/index.csv   # provenance graph (HTML)
```
