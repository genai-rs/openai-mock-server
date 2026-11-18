#!/usr/bin/env bash
# Regenerates src/generated (the axum server and its models) from OpenAI's OpenAPI specification with timvw-rust
# (https://github.com/timvw/openapi-generator-timvw-rust). The generator writes a whole crate; only its models,
# headers and server modules are kept, as modules of this crate (src/lib.rs declares them).
#
#   SKIP_SPEC_FETCH=1   regenerate from the checked-in openapi.json (to see a generator change on its own)
#   GENERATOR_IMAGE=... another generator image, e.g. a local build
set -euo pipefail

OPENAPI_GENERATOR_VERSION="${OPENAPI_GENERATOR_VERSION:-7.27.0}"
TIMVW_RUST_VERSION="${TIMVW_RUST_VERSION:-0.38.1}"
GENERATOR_IMAGE="${GENERATOR_IMAGE:-ghcr.io/timvw/openapi-generator-timvw-rust:${TIMVW_RUST_VERSION}-og${OPENAPI_GENERATOR_VERSION}}"
OPENAPI_GENERATOR_LOG_LEVEL="${OPENAPI_GENERATOR_LOG_LEVEL:-warn}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"
export PYTHONDONTWRITEBYTECODE=1

if [ "${SKIP_SPEC_FETCH:-0}" = "1" ]; then
    echo "SKIP_SPEC_FETCH=1: using the checked-in openapi.json ($(cat openapi.revision))"
else
    bash "$SCRIPT_DIR/fetch_spec.sh"
fi

# The working directory is the project's, so the paths in generator-config.json (apiFeaturesFile) resolve.
echo "Generating the server with $GENERATOR_IMAGE"
rm -rf target/generated
mkdir -p target/generated
docker run --rm \
    -v "$PROJECT_ROOT:/local" \
    -w /local \
    -u "$(id -u):$(id -g)" \
    -e JAVA_OPTS="-Dlog.level=${OPENAPI_GENERATOR_LOG_LEVEL}" \
    "$GENERATOR_IMAGE" generate \
    -i /local/openapi.json \
    -g timvw-rust \
    -o /local/target/generated \
    -c /local/scripts/generator-config.json \
    --skip-validate-spec

# Keep the modules; the generated lib.rs, Cargo.toml, README and model docs are not used.
rm -rf src/generated
mkdir -p src/generated
cp -R target/generated/src/models src/generated/models
cp target/generated/src/headers.rs target/generated/src/server.rs src/generated/

# Cargo.toml is written by hand: its API features and dependencies must be the generator's.
python3 -I "$SCRIPT_DIR/check_manifest.py" target/generated/Cargo.toml Cargo.toml

cargo fmt --all
cargo build --all-features
echo "Generated src/generated from openapi.json at $(cat openapi.revision)"
