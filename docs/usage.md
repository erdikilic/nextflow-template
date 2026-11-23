# Usage

## Input: samplesheet

Provide a CSV via `--input`. The workflow takes long-read data only — Oxford
Nanopore and PacBio. Columns:

| Column     | Description                                                          |
| ---------- | -------------------------------------------------------------------- |
| `sample`   | Sample name (no spaces). Becomes the record's `id`.                  |
| `platform` | Optional. `ont_r9`, `ont_r10` or `pacbio_hifi`; empty: `--platform`. |
| `fastq`    | One long-read FASTQ. `.fastq`/`.fq`, optionally `.gz`.               |

The platform names the chemistry, not the basecalling model: `ont_r9` and
`ont_r10` are Oxford Nanopore R9.4.1 and R10.4.1 flow cells, `pacbio_hifi` is
PacBio HiFi. A row whose `platform` cell is empty, or a samplesheet without the
column, takes `--platform` (default `ont_r10`); a value in the samplesheet wins.

A sample that arrives as several files — an ONT barcode directory split across
many FASTQs, or a re-sequenced run — gets **one row per file**, all sharing the
same `sample` name. The `INPUT:CHECK` stage groups those rows and `HANDLE_DATA`
merges them into a single FASTQ per sample.

```csv
sample,platform,fastq
ONT_BARCODE01,ont_r10,/data/barcode01/fastq_runid_a.fastq.gz
ONT_BARCODE01,ont_r10,/data/barcode01/fastq_runid_b.fastq.gz
HIFI_SAMPLE01,pacbio_hifi,/data/pacbio/hifi_reads.fastq.gz
```

Nextflow loads the samplesheet into `SamplesheetRow` records
([`INPUT:CHECK`](../subworkflows/local/input/check/main.nf)) before the run
starts: a `platform` outside the list or a FASTQ that does not exist fails the run
at once. `INPUT:CHECK` then rejects a `--platform` outside the list, sample names
with whitespace, files without a FASTQ extension, and a sample listed with two
platforms. Relative FASTQ paths resolve
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
| `--platform`         | `ont_r10` | Platform of an empty cell. |
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
raise its label, or override one step in a custom config passed with `-c`:

```groovy
process {
    withName: '.*:SAMPLE:EXAMPLE' {
        cpus   = 32
        memory = 128.GB
    }
}
```

Every task is named by its call path: the workflow, the scope, the stage and the
step, such as `NEXTFLOW_TEMPLATE:READS:QC:SEQUALI`. A `withName:` pattern anchored
on the tail of that path, as above, matches whether the workflow runs directly or
is included by another one, which puts its own name in front
(`LONGREAD:NEXTFLOW_TEMPLATE:READS:QC:SEQUALI`). An exact qualified name matches
only when the workflow runs directly, a partial path such as `'READS:QC:SEQUALI'`
matches nothing, and a plain process name (`SEQUALI`) matches the process wherever
it is called. A selector that matches nothing prints a warning and changes
nothing.

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

- **Global cache** — Seqera Platform (Seqera Cloud and Enterprise 26.2, with
  Nextflow 26.10 or later) can keep one content-addressed cache for a workspace
  in AWS, Google Cloud or Azure storage. A task is keyed by its inputs and
  script alone, without the session or the process name, so an identical task
  from any run or workflow in the workspace is restored instead of run again,
  with or without `-resume`. It is a Platform feature, so the workflow needs no
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

## Including the workflow in another workflow

Another workflow can include this one under an alias and call it like any
named workflow; including a whole workflow is experimental in Nextflow 26.10.
The `params` block is its input and the `output {}` block its result: the
caller passes one record with a field per parameter, and decides what to
publish in its own `output {}` block.

```nextflow
nextflow.enable.types = true

include { workflow as LONGREAD } from './nextflow-template/main.nf'

workflow {
    main:
    longread = LONGREAD(record(input: rows))
    longread.reads.view()      // Channel<SamplesheetRow>
    longread.versions.view()   // Channel<ToolVersion>
}
```

`rows` is a channel of `record(sample: ..., platform: ..., fastq: ...)` values,
for example the output of an upstream workflow. A parameter with a default, such
as `sequali_args`, can be left out of the record.

To offer every parameter of this workflow to the caller's users, import the
`params` block as a record type. Each parameter is then set as
`--longread.<name>`:

```nextflow
nextflow.enable.types = true

include { params as LongreadParams ; workflow as LONGREAD } from './nextflow-template/main.nf'

params {
    longread: LongreadParams
}

workflow {
    main:
    longread = LONGREAD(params.longread)
}
```

```bash
nextflow run caller.nf -profile docker --longread.input samplesheet.csv
```

Inclusion captures the scripts only, so the including workflow supplies the
configuration: the container engine, the resource labels of `conf/base.config`
and the `nf-schema` plugin. [`tests/composition/`](../tests/composition) holds a
runnable caller of each form.
