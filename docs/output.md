# Output

All results are written under `--outdir` (default `results/`).

```text
results/
├── reads/
│   └── <sample>.merged.fastq.gz    # every FASTQ for the sample, concatenated
├── example/
│   └── <sample>.linecount.txt      # per-sample output of the EXAMPLE process
└── pipeline_info/
    ├── execution_report.html       # Nextflow run report
    ├── execution_timeline.html     # per-task timeline
    ├── execution_trace.txt         # per-task trace (resources, exit status)
    ├── pipeline_dag.html           # workflow DAG
    └── collated_versions.yml       # versions of every tool that ran, from the `versions` topic
```

Replace the `example/` section with your real stages. Follow the naming
convention: publish standalone files as `<id>.<descriptor>.<ext>` and keep
provenance (assembler/refiner/etc.) in the directory path.
