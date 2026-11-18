#!/usr/bin/env bash
# Local equivalents of this repo's own CI jobs, run by genai-rs/.github scripts/local-ci.sh after the shared checks.
set -euo pipefail

python3 -m unittest discover -s scripts/tests -v
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features --lib --tests
