version 1.3

task summarize_reference {
    input {
        File fasta
    }

    command <<<
        ref-summary "~{fasta}" --output summary.json
    >>>

    output {
        File summary = "summary.json"
    }

    requirements {
        container: "ref-summary:v0.1.0"
    }
}
