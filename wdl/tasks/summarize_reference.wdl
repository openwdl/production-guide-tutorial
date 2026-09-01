version 1.3

struct FastaMetrics {
    meta {
        description: "Deterministic sequence counts emitted by ref-summary."
    }

    parameter_meta {
        schema_version: "Version of the ref-summary JSON schema."
        sequence_count: "Number of FASTA records."
        total_bases: "Total number of nucleotide symbols."
        gc_bases: "Number of literal G and C bases."
        n_bases: "Number of N bases."
        ambiguous_bases: "Number of other IUPAC symbols."
        minimum_length: "Length of the shortest FASTA record."
        maximum_length: "Length of the longest FASTA record."
    }

    Int schema_version
    Int sequence_count
    Int total_bases
    Int gc_bases
    Int n_bases
    Int ambiguous_bases
    Int minimum_length
    Int maximum_length
}

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
        container: "Container image containing ref-summary, preferably pinned by digest."
        cpu: "Number of processor cores to request."
        memory: "Amount of memory to request, including its unit."
    }

    input {
        File fasta
        String container = "ref-summary:v0.1.0"
        Int cpu = 1
        String memory = "256 MiB"
    }

    command <<<
        set -euo pipefail
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
