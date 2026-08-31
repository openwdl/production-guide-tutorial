use assert_cmd::Command;
use predicates::prelude::*;
use std::fs;
use tempfile::tempdir;

const FASTA: &str = ">chromosome\nACGTACGTNN\n>plasmid\nGGRYSW\n";

#[test]
fn writes_expected_json_to_stdout() {
    let directory = tempdir().unwrap();
    let input = directory.path().join("input.fasta");
    fs::write(&input, FASTA).unwrap();

    Command::cargo_bin("ref-summary")
        .unwrap()
        .arg(input)
        .assert()
        .success()
        .stdout(predicate::str::contains("\"gc_bases\": 6"));
}

#[test]
fn writes_output_file_atomically() {
    let directory = tempdir().unwrap();
    let input = directory.path().join("input.fasta");
    let output = directory.path().join("summary.json");
    fs::write(&input, FASTA).unwrap();

    Command::cargo_bin("ref-summary")
        .unwrap()
        .arg(&input)
        .args(["--output", output.to_str().unwrap()])
        .assert()
        .success()
        .stdout("");

    assert!(
        fs::read_to_string(output)
            .unwrap()
            .contains("\"sequence_count\": 2")
    );
}

#[test]
fn reports_missing_input_without_creating_output() {
    let directory = tempdir().unwrap();
    let output = directory.path().join("summary.json");

    Command::cargo_bin("ref-summary")
        .unwrap()
        .arg(directory.path().join("missing.fasta"))
        .args(["--output", output.to_str().unwrap()])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("failed to open"));

    assert!(!output.exists());
}

#[test]
fn removes_temporary_file_when_output_cannot_be_persisted() {
    let directory = tempdir().unwrap();
    let input = directory.path().join("input.fasta");
    let output = directory.path().join("existing-directory");
    fs::write(&input, FASTA).unwrap();
    fs::create_dir(&output).unwrap();

    Command::cargo_bin("ref-summary")
        .unwrap()
        .arg(&input)
        .args(["--output", output.to_str().unwrap()])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("failed to write"));

    let entries = fs::read_dir(directory.path()).unwrap().count();
    assert_eq!(entries, 2, "the failed atomic write left a temporary file");
}
