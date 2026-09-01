version 1.3

struct ReferenceFile {
    meta {
        description: "A localized FASTA file and the stable identity preserved with it."
    }

    parameter_meta {
        accession: "Stable reference identifier shown in audit reports."
        label: "Unique human-readable name shown in audit reports."
        fasta: "Uncompressed nucleotide FASTA file."
    }

    String accession
    String label
    File fasta
}

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
