version 1.3

import "../types.wdl"

task summarize_reference {
    meta {
        description: "Calculate deterministic sequence metrics for one FASTA reference."
        outputs: {
            metrics_json: "JSON sequence metrics emitted by ref-summary.",
            metrics: "Typed sequence metrics read from the JSON output.",
        }
    }

    parameter_meta {
        fasta: "Uncompressed nucleotide FASTA file to summarize."
        validation: "Successful preflight validation report for the complete request."
        container: "Container image containing ref-summary, preferably pinned by digest."
        cpu: "Number of processor cores to request."
        memory: "Amount of memory to request, including its unit."
    }

    input {
        File fasta
        File validation
        String container = "ref-summary:v0.1.0"
        Int cpu = 1
        String memory = "256 MiB"
    }

    command <<<
        set -euo pipefail
        test -s "~{validation}"
        ref-summary "~{fasta}" --output summary.json
    >>>

    output {
        File metrics_json = "summary.json"
        FastaMetrics metrics = read_json(metrics_json)
    }

    requirements {
        container: container
        cpu: cpu
        memory: memory
        max_retries: 1
    }
}
