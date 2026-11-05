# Output

All results are written under `--outdir` (default `results/`). The layout is
declared once, in the `output {}` block of [`main.nf`](../main.nf); the
`--publish_dir_mode` parameter sets how files are placed there (`copy` by default).

```text
results/
├── reads/
│   ├── <sample>.merged.fastq.gz    # every FASTQ for the sample, concatenated
│   └── samplesheet.csv             # index of the merged reads, in the --input format
├── qc/
│   └── sequali/
│       ├── <sample>.sequali.html   # Sequali read-QC report
│       ├── <sample>.sequali.json   # the same metrics as JSON
│       └── index.csv               # sample, platform, html, json for every sample
├── example/
│   └── <sample>.linecount.txt      # per-sample output of the EXAMPLE process
└── workflow_info/
    ├── execution_report.html       # Nextflow run report
    ├── execution_timeline.html     # per-task timeline
    ├── execution_trace.txt         # per-task trace (resources, exit status)
    ├── workflow_dag.html           # workflow DAG
    └── versions.yml                # process, tool and version of every tool that ran
```

`reads/samplesheet.csv` lists every published FASTQ with its sample and
platform, so the merged reads can seed another run with
`--input results/reads/samplesheet.csv`.

At the end of a run Nextflow prints the published outputs;
`-output-format json` prints the same list as JSON.

## How a stage is published

Sequali shows the whole path from a process to `results/`:

1. **Process** — `SEQUALI` ([`modules/local/sequali`](../modules/local/sequali/main.nf))
   takes `record(id, fastq)` and its `args` (from `--sequali_args`) and returns
   `record(id, html, json)`.
2. **Named workflow** — `NEXTFLOW_TEMPLATE` joins those records with the other
   results of each sample by `id` and emits one `SampleResult` record per sample.
3. **`publish:`** — the entry workflow in [`main.nf`](../main.nf) turns each
   value into a record and names the channel:
   `qc = results.map { r -> record(sample: r.id, platform: r.platform, html: r.html, json: r.json) }`.
4. **`output {}`** — the `qc` target's `path` closure maps each file of a record
   to its own target, `qc/sequali/<sample>.sequali.html` and `.json`, and its
   `index` block writes one row per record to `qc/sequali/index.csv`, with the
   paths of the published copies.

To add a stage, emit its channel from the named workflow, add a `publish:`
assignment, and add an `output {}` target with the same name. `path` takes one of
three forms:

- a string, the directory for every file of the channel: `path 'example'`;
- a closure returning a directory per value, for example
  `path { r -> "qc/${r.sample}/" }` for one directory per sample;
- a closure returning a map from each file to its target, which renames files or
  sends them to different directories, as the `qc` target does.

Replace the `example/` section with your real stages. Follow the naming
convention: publish standalone files as `<id>.<descriptor>.<ext>` and keep
provenance (assembler/refiner/etc.) in the directory path.
