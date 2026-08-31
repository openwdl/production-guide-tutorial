# Every image builds on an existing base image instead of assembling an operating-system
# environment from nothing. Start a temporary build stage from the official Rust image,
# which already contains the Rust compiler and its supporting tools.
FROM rust:1.98.1-bookworm AS builder

# The working directory is the folder where later commands run by default. Use /build
# so copied source and generated build files stay together in a known location.
WORKDIR /build

# COPY moves files from the course directory on your computer into the image. Copy the
# complete ref-summary package, including its source and dependency files, into /build.
COPY tools/ref-summary/ .

# Compile an optimized executable using the locked dependencies.
RUN cargo build --locked --release

# A second FROM starts a new build stage. Start the final, production image from a
# smaller Debian base because running ref-summary does not require the Rust compiler.
FROM debian:trixie-slim

# --from=builder copies across stages instead of from your computer. Take only the
# finished executable from the temporary builder and leave its source and build tools.
COPY --from=builder /build/target/release/ref-summary /usr/local/bin/ref-summary

# Run ref-summary when a container starts from this image.
ENTRYPOINT ["ref-summary"]
