# Usage

## Input: samplesheet

Provide a CSV via `--input`. The pipeline takes long-read data only — Oxford
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
| `--max_cpus`         | `14`      | Per-job CPU ceiling.       |
| `--max_memory`       | `30.GB`   | Per-job memory ceiling.    |
| `--publish_dir_mode` | `copy`    | How results are published. |

Run `nextflow run . --help` for the full, schema-generated parameter list.
