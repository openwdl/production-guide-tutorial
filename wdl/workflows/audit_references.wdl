version 1.3

import "../tasks/aggregate_summaries.wdl" as aggregate
import "../tasks/summarize_reference.wdl" as summarize
import "../tasks/validate_references.wdl" as validation
#@ except: UnusedImport
import "../types.wdl"

workflow audit_references {
    input {
        Array[ReferenceFile]+ references
        String ref_summary_container = "ref-summary:v0.1.0"
        String ref_summary_version = "0.1.0"
        Boolean emit_tsv = true
    }

    scatter (reference in references) {
        String accession = reference.accession
        String label = reference.label
    }

    String accessions_json = read_string(write_json(accession))
    String labels_json = read_string(write_json(label))

    call validation.validate_references {
        accessions_json,
        labels_json,
    }

    scatter (reference in references) {
        call summarize.summarize_reference {
            fasta = reference.fasta,
            container = ref_summary_container,
            validation = validate_references.report,
        }
    }

    call aggregate.aggregate_summaries {
        accessions_json,
        labels_json,
        metrics = summarize_reference.metrics_json,
        ref_summary_version,
        ref_summary_container,
    }

    if (emit_tsv) {
        call aggregate.render_tsv {
            report = aggregate_summaries.report,
        }
    }

    output {
        File audit_json = aggregate_summaries.report
        File? audit_tsv = render_tsv.report_tsv
        Array[File]+ summaries = summarize_reference.metrics_json
    }
}
