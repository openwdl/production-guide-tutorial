use serde::Serialize;
use std::io::{self, BufRead};

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Summary {
    pub schema_version: u8,
    pub sequence_count: u64,
    pub total_bases: u64,
    pub gc_bases: u64,
    pub n_bases: u64,
    pub ambiguous_bases: u64,
    pub minimum_length: u64,
    pub maximum_length: u64,
}

#[derive(Default)]
struct Counts {
    sequence_count: u64,
    total_bases: u64,
    gc_bases: u64,
    n_bases: u64,
    ambiguous_bases: u64,
    minimum_length: Option<u64>,
    maximum_length: u64,
    current_length: Option<u64>,
}

impl Counts {
    fn finish_record(&mut self) -> Result<(), String> {
        let length = self
            .current_length
            .take()
            .ok_or_else(|| "sequence data appeared before a FASTA header".to_string())?;
        if length == 0 {
            return Err("FASTA records must contain at least one base".to_string());
        }
        self.sequence_count += 1;
        self.minimum_length = Some(
            self.minimum_length
                .map_or(length, |minimum| minimum.min(length)),
        );
        self.maximum_length = self.maximum_length.max(length);
        Ok(())
    }

    fn add_base(&mut self, base: u8) -> Result<(), String> {
        let upper = base.to_ascii_uppercase();
        match upper {
            b'A' | b'T' => {}
            b'C' | b'G' => self.gc_bases += 1,
            b'N' => self.n_bases += 1,
            b'R' | b'Y' | b'S' | b'W' | b'K' | b'M' | b'B' | b'D' | b'H' | b'V' | b'U' => {
                self.ambiguous_bases += 1;
            }
            _ => return Err(format!("invalid nucleotide symbol: {}", char::from(base))),
        }
        self.total_bases += 1;
        *self
            .current_length
            .as_mut()
            .ok_or_else(|| "sequence data appeared before a FASTA header".to_string())? += 1;
        Ok(())
    }
}

pub fn summarize<R: BufRead>(reader: R) -> Result<Summary, String> {
    let mut counts = Counts::default();

    for line in reader.lines() {
        let line = line.map_err(|error| format!("failed to read FASTA: {error}"))?;
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        if trimmed.starts_with('>') {
            if trimmed.len() == 1 {
                return Err("FASTA headers must contain an identifier".to_string());
            }
            if counts.current_length.is_some() {
                counts.finish_record()?;
            }
            counts.current_length = Some(0);
            continue;
        }
        for base in trimmed.bytes().filter(|byte| !byte.is_ascii_whitespace()) {
            counts.add_base(base)?;
        }
    }

    if counts.current_length.is_none() {
        return Err("FASTA contains no records".to_string());
    }
    counts.finish_record()?;

    Ok(Summary {
        schema_version: 1,
        sequence_count: counts.sequence_count,
        total_bases: counts.total_bases,
        gc_bases: counts.gc_bases,
        n_bases: counts.n_bases,
        ambiguous_bases: counts.ambiguous_bases,
        minimum_length: counts.minimum_length.unwrap_or(0),
        maximum_length: counts.maximum_length,
    })
}

pub fn write_json<W: io::Write>(summary: &Summary, mut writer: W) -> Result<(), String> {
    serde_json::to_writer_pretty(&mut writer, summary)
        .map_err(|error| format!("failed to serialize summary: {error}"))?;
    writeln!(writer).map_err(|error| format!("failed to write summary: {error}"))?;
    writer
        .flush()
        .map_err(|error| format!("failed to flush summary: {error}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn summarizes_wrapped_mixed_case_iupac_sequences() {
        let input = b">chromosome\r\nacgt\r\nACGTNN\r\n>plasmid\nGGRYSW\n";
        let summary = summarize(Cursor::new(input)).unwrap();
        assert_eq!(
            summary,
            Summary {
                schema_version: 1,
                sequence_count: 2,
                total_bases: 16,
                gc_bases: 6,
                n_bases: 2,
                ambiguous_bases: 4,
                minimum_length: 6,
                maximum_length: 10,
            }
        );
    }

    #[test]
    fn rejects_sequence_before_header() {
        let error = summarize(Cursor::new(b"ACGT\n")).unwrap_err();
        assert!(error.contains("before a FASTA header"));
    }

    #[test]
    fn rejects_empty_input_and_empty_records() {
        assert_eq!(
            summarize(Cursor::new(b"".as_slice())).unwrap_err(),
            "FASTA contains no records"
        );
        assert_eq!(
            summarize(Cursor::new(b">empty\n".as_slice())).unwrap_err(),
            "FASTA records must contain at least one base"
        );
    }

    #[test]
    fn rejects_invalid_symbols() {
        let error = summarize(Cursor::new(b">bad\nACGT!\n")).unwrap_err();
        assert_eq!(error, "invalid nucleotide symbol: !");
    }

    #[test]
    fn reports_flush_failures() {
        struct FlushFailure;

        impl io::Write for FlushFailure {
            fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
                Ok(buffer.len())
            }

            fn flush(&mut self) -> io::Result<()> {
                Err(io::Error::new(io::ErrorKind::BrokenPipe, "closed output"))
            }
        }

        let summary = summarize(Cursor::new(b">reference\nACGT\n")).unwrap();
        let error = write_json(&summary, FlushFailure).unwrap_err();
        assert_eq!(error, "failed to flush summary: closed output");
    }
}
