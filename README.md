# Production guide tutorial

This repository accompanies the OpenWDL **Production guide**. It builds a WDL 1.3
pipeline that validates, summarizes, and combines local reference FASTA files with a
small Rust command-line program.

Each `chapter/NN-topic` branch is the starting point for the section with the same name.
Create an independent local branch from the corresponding branch on `origin`, complete
the section, and commit your work locally. Routine coursework does not need to be pushed
unless the section uses a GitHub service.

## What it contains

- `tools/ref-summary/`: a streaming FASTA summarizer written in Rust.
- `wdl/tasks/`: reusable validation, summarization, and aggregation tasks.
- `wdl/workflows/audit_references.wdl`: deterministic analysis of local FASTA files.
- `examples/fixture.inputs.json`: local example inputs for the complete workflow.
- `tests/`: small synthetic fixtures and expected outputs.
- `.github/workflows/`: deterministic CI, GitHub Pages deployment, and release automation.

For a reusable starting point for other WDL projects, see
[`openwdl/template`](https://github.com/openwdl/template). This repository is a worked
tutorial rather than a general template.

## Local verification

The guide introduces the Docker build, WDL checks, task tests, JSON comparison,
documentation generation, and local workflow run in the sections where they first
matter. Run those commands before sharing changes.
