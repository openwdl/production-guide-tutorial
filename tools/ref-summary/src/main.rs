use clap::Parser;
use ref_summary::{summarize, write_json};
use std::fs::File;
use std::io::{self, BufReader, BufWriter};
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use tempfile::NamedTempFile;

#[derive(Parser)]
#[command(version, about = "Summarize an uncompressed nucleotide FASTA file")]
struct Args {
    /// Input FASTA file
    fasta: PathBuf,

    /// Write JSON to this path instead of standard output
    #[arg(short, long)]
    output: Option<PathBuf>,
}

fn run(args: Args) -> Result<(), String> {
    let input = File::open(&args.fasta)
        .map_err(|error| format!("failed to open {}: {error}", args.fasta.display()))?;
    let summary = summarize(BufReader::new(input))?;

    match args.output {
        Some(path) => write_atomic(&path, &summary),
        None => write_json(&summary, BufWriter::new(io::stdout().lock())),
    }
}

fn write_atomic(path: &Path, summary: &ref_summary::Summary) -> Result<(), String> {
    let parent = path
        .parent()
        .filter(|path| !path.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    let mut temporary = NamedTempFile::new_in(parent)
        .map_err(|error| format!("failed to create output beside {}: {error}", path.display()))?;
    write_json(summary, temporary.as_file_mut())?;
    temporary
        .as_file_mut()
        .sync_all()
        .map_err(|error| format!("failed to flush {}: {error}", path.display()))?;
    temporary
        .persist(path)
        .map_err(|error| format!("failed to write {}: {}", path.display(), error.error))?;
    Ok(())
}

fn main() -> ExitCode {
    match run(Args::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("error: {error}");
            ExitCode::FAILURE
        }
    }
}
