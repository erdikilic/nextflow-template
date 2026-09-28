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
│       ├── <sample>.html           # Sequali read-QC report
│       ├── <sample>.json           # the same metrics as JSON
│       └── index.csv               # sample, platform, html, json for every sample
├── example/
│   └── <sample>.linecount.txt      # per-sample output of the EXAMPLE process
└── workflow_info/
    ├── execution_report.html       # Nextflow run report
    ├── execution_timeline.html     # per-task timeline
    ├── execution_trace.txt         # per-task trace (resources, exit status)
    ├── workflow_dag.html           # workflow DAG
    └── collated_versions.yml       # versions of every tool that ran, from the `versions` topic
```

`reads/samplesheet.csv` lists every published FASTQ with its sample and
platform, so the merged reads can seed another run with
`--input results/reads/samplesheet.csv`.

At the end of a run Nextflow prints the published outputs;
`-output-format json` prints the same list as JSON.

## How a stage is published

Sequali shows the whole path from a process to `results/`:

1. **Process** — `SEQUALI` (the nf-core/sequali module) declares its outputs,
   `html` and `json`. It sets no `publishDir`; its tool arguments live in
   [`conf/modules/qc.config`](../conf/modules/qc.config).
2. **Named workflow** — `NEXTFLOW_TEMPLATE` joins the two outputs per sample and
   emits them: `qc = SEQUALI.out.html.join(SEQUALI.out.json)`.
3. **`publish:`** — the entry workflow in [`main.nf`](../main.nf) turns each
   value into a record and names the channel:
   `qc = NEXTFLOW_TEMPLATE.out.qc.map { meta, html, json -> [sample: meta.id, platform: meta.platform, html: html, json: json] }`.
4. **`output {}`** — the `qc` target places every file of that channel under
   `qc/sequali/`, and its `index` block writes one row per record to
   `qc/sequali/index.csv`, with the paths of the published copies.

To add a stage, emit its channel from the named workflow, add a `publish:`
assignment, and add an `output {}` target with the same name. A target can also
compute the directory per value, for example `path { r -> "qc/${r.sample}" }`
for one directory per sample.

Replace the `example/` section with your real stages. Follow the naming
convention: publish standalone files as `<id>.<descriptor>.<ext>` and keep
provenance (assembler/refiner/etc.) in the directory path.
