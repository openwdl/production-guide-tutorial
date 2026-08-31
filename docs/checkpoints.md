# Chapter checkpoints

Each branch is the starting snapshot for the named section. It contains the work
completed in earlier sections, but not the changes taught in that section.

| Branch | Starting snapshot |
| --- | --- |
| `chapter/01-getting-started` | Repository purpose, licenses, README, and checkpoint map |
| `chapter/02-installing-the-tools` | Initial repository files before local editor configuration |
| `chapter/03-git-crash-course` | Editor, Git, line-ending, and ignore configuration |
| `chapter/04-command-line-tools` | Course setup before the first FASTA fixture |
| `chapter/05-containers` | `ref-summary` source, tests, expected JSON, and the completed command-line exercise |
| `chapter/06-units-of-work-tasks` | Local `ref-summary:v0.1.0` container image |
| `chapter/07-execution-graphs-workflows` | Production-ready `summarize_reference` task |
| `chapter/08-polishing-the-code` | Local validated scatter-gather workflow and example inputs |
| `chapter/09-testing-your-pipeline` | Formatted, linted, documented, and locally executed WDL project |
| `chapter/10-versioning-and-changelogs` | Valid and malformed FASTA task tests |
| `chapter/11-automating-quality` | Pipeline version `0.1.0` and changelog |
| `chapter/12-release-a-pipeline` | Deterministic CI and GitHub Pages documentation deployment |
| `chapter/13-deploy-a-pipeline` | Native archives, checksums, multi-platform image, and GitHub Release automation |

The checkpoints are comparison and recovery points. Do not rewrite a published checkpoint
branch; corrections use normal follow-up commits and update the corresponding tutorial
page in the same change.
