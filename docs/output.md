# Output

All results are written under `--outdir` (default `results/`). The layout is
declared once, in the `output {}` block of [`main.nf`](../main.nf); the
`--publish_dir_mode` parameter sets how files are placed there (`copy` by default).

```text
results/
├── reads/
│   ├── <sample>.merged.fastq.gz    # every FASTQ for the sample, concatenated
│   └── samplesheet.csv             # index of the merged reads, in the --input format
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

Replace the `example/` section with your real stages. Follow the naming
convention: publish standalone files as `<id>.<descriptor>.<ext>` and keep
provenance (assembler/refiner/etc.) in the directory path.
