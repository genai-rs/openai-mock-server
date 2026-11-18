#!/usr/bin/env bash
# Downloads OpenAI's OpenAPI specification at the current revision of its repository, and records that revision in
# openapi.revision: the spec is the contract, and the revision says which version of it this crate serves.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SPEC_REPOSITORY="https://github.com/openai/openai-openapi"
SPEC_PATH="$PROJECT_ROOT/openapi.json"
TEMP_PATH="$(mktemp "$PROJECT_ROOT/.openapi.json.XXXXXX")"
trap 'rm -f "$TEMP_PATH"' EXIT

revision="$(git ls-remote "$SPEC_REPOSITORY.git" refs/heads/main | cut -f1)"
test -n "$revision" || { echo "no revision for $SPEC_REPOSITORY main" >&2; exit 1; }
url="https://raw.githubusercontent.com/openai/openai-openapi/$revision/openapi.json"

echo "Fetching $url"
curl --fail --location --silent --show-error --retry 3 --output "$TEMP_PATH" "$url"

# An HTTP error page or a truncated download must never reach the generator.
python3 -I - "$TEMP_PATH" <<'PY'
import json, sys
spec = json.load(open(sys.argv[1], encoding="utf-8"))
assert spec.get("openapi", "").startswith("3."), "not an OpenAPI 3 document"
assert len(spec.get("paths", {})) > 100, "too few paths: a partial document?"
PY

mv "$TEMP_PATH" "$SPEC_PATH"
printf '%s\n' "$revision" > "$PROJECT_ROOT/openapi.revision"
echo "openapi.json is $SPEC_REPOSITORY at $revision"
