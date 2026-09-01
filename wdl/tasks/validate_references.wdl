version 1.3

task validate_references {
    input {
        env String accessions_json
        env String labels_json
        String container = "python:3.14-slim"
    }

    command <<<
        set -euo pipefail
        python3 - <<'PY'
        import json
        import os
        import pathlib

        accessions = json.loads(os.environ["accessions_json"])
        labels = json.loads(os.environ["labels_json"])

        if len(accessions) != len(labels):
            raise SystemExit("accessions and labels must have equal lengths")
        if len(set(accessions)) != len(accessions):
            raise SystemExit("reference accessions must be unique")
        if len(set(labels)) != len(labels):
            raise SystemExit("reference labels must be unique")

        if any(not value.strip() for value in accessions):
            raise SystemExit("reference accessions must not be blank")
        if any(not value.strip() for value in labels):
            raise SystemExit("reference labels must not be blank")

        pathlib.Path("validation.json").write_text(
            json.dumps({"schema_version": 1, "reference_count": len(accessions)}) + "\n"
        )
        PY
    >>>

    output {
        File report = "validation.json"
    }

    requirements {
        container: container
        cpu: 1
        memory: "128 MiB"
    }
}
