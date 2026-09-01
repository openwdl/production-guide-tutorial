version 1.3

task aggregate_summaries {
    meta {
        description: "Combine ordered per-reference metrics into one versioned JSON report."
        outputs: {
            report: "Combined JSON audit report with ref-summary provenance.",
        }
    }

    parameter_meta {
        accessions_json: "JSON array of ordered stable reference identifiers."
        labels_json: "JSON array of ordered unique report labels."
        metrics: "Ordered JSON metric files emitted by ref-summary."
        ref_summary_version: "Version of ref-summary used for the audit."
        ref_summary_container: "Container image used to execute ref-summary."
        container: "Container image containing Python."
    }

    input {
        env String accessions_json
        env String labels_json
        Array[File]+ metrics
        env String ref_summary_version
        env String ref_summary_container
        String container = "python:3.14-slim"
    }

    File metrics_manifest = write_lines(metrics)

    command <<<
        set -euo pipefail
        python3 - "~{metrics_manifest}" <<'PY'
        import json
        import os
        import pathlib
        import sys

        accessions = json.loads(os.environ["accessions_json"])
        labels = json.loads(os.environ["labels_json"])
        paths = pathlib.Path(sys.argv[1]).read_text().splitlines()
        if not (len(accessions) == len(labels) == len(paths)):
            raise SystemExit("accessions, labels, and metrics must have equal lengths")

        references = []
        for accession, label, path in zip(accessions, labels, paths, strict=True):
            metrics = json.loads(pathlib.Path(path).read_text())
            references.append({"accession": accession, "label": label, **metrics})

        report = {
            "schema_version": 1,
            "ref_summary_version": os.environ["ref_summary_version"],
            "ref_summary_container": os.environ["ref_summary_container"],
            "references": references,
        }
        pathlib.Path("audit.json").write_text(json.dumps(report, indent=2) + "\n")
        PY
    >>>

    output {
        File report = "audit.json"
    }

    requirements {
        container: container
        cpu: 1
        memory: "256 MiB"
    }
}

task render_tsv {
    meta {
        description: "Convert a combined JSON audit report to a stable TSV artifact."
        outputs: {
            report_tsv: "Flat TSV audit report with one row per reference.",
        }
    }

    parameter_meta {
        report: "Combined JSON audit report."
        container: "Container image containing Python."
    }

    input {
        File report
        String container = "python:3.14-slim"
    }

    command <<<
        set -euo pipefail
        python3 - "~{report}" <<'PY'
        import csv
        import json
        import pathlib
        import sys

        report = json.loads(pathlib.Path(sys.argv[1]).read_text())
        fields = [
            "accession", "label", "sequence_count", "total_bases", "gc_bases",
            "n_bases", "ambiguous_bases", "minimum_length", "maximum_length",
        ]
        with pathlib.Path("audit.tsv").open("w", newline="") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=fields,
                delimiter="\t",
                lineterminator="\n",
                extrasaction="ignore",
            )
            writer.writeheader()
            writer.writerows(report["references"])
        PY
    >>>

    output {
        File report_tsv = "audit.tsv"
    }

    requirements {
        container: container
        cpu: 1
        memory: "256 MiB"
    }
}
