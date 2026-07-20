# Usage

## Input: samplesheet

Provide a CSV via `--input`. Both short-read (Illumina) and long-read
(Nanopore/PacBio) inputs are supported via the `platform` column. Columns:

| Column     | Description                                                                       |
| ---------- | --------------------------------------------------------------------------------- |
| `sample`   | Unique sample name (no spaces). Becomes `meta.id`.                                |
| `platform` | `illumina`, `nanopore`, or `pacbio`. Becomes `meta.platform`.                     |
| `fastq_1`  | Short-read R1, **or** the single long-read FASTQ. `.fastq`/`.fq`, optional `.gz`. |
| `fastq_2`  | Short-read R2. Leave empty for single-end short reads and for long reads.         |

```csv
sample,platform,fastq_1,fastq_2
ILLUMINA_PAIRED,illumina,/data/s1_R1.fastq.gz,/data/s1_R2.fastq.gz
ILLUMINA_SINGLE,illumina,/data/s2.fastq.gz,
NANOPORE_LONG,nanopore,/data/ont_run.fastq.gz,
```

The samplesheet is validated against [`assets/schema_input.json`](../assets/schema_input.json)
by the `nf-schema` plugin. `INPUT_CHECK` sets `meta.single_end` and
`meta.long_reads` so modules can branch (e.g. `minimap2 -x map-ont` for long reads
vs `-x sr` for short reads).

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
| `--max_cpus`         | `14`      | Per-job CPU ceiling.       |
| `--max_memory`       | `30.GB`   | Per-job memory ceiling.    |
| `--publish_dir_mode` | `copy`    | How results are published. |

Run `nextflow run . --help` for the full, schema-generated parameter list.
