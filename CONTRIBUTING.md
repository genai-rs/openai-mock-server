# Contributing

Changes go through pull requests against `main`, with [Conventional Commits](https://www.conventionalcommits.org)
titles: [release-plz](https://release-plz.ieni.dev) derives the versions and the changelog from them.

- **`src/generated`** is written by `scripts/generate.sh` (Docker), from `openapi.json` with
  [timvw-rust](https://github.com/timvw/openapi-generator-timvw-rust): do not edit it. `openapi.revision` is the
  revision of [OpenAI's specification](https://github.com/openai/openai-openapi) it was generated from. The Generate
  workflow proposes a regeneration when the specification changes. `SKIP_SPEC_FETCH=1 scripts/generate.sh`
  regenerates from the checked-in specification, to see a generator change on its own.
- **The mock** is the rest of `src`: `api.rs` implements the generated traits with the scripts, `reply.rs` writes the
  replies, `fixtures.rs` holds the bodies. A new scripted operation is a line in `api.rs`, its name in `op`, a
  fixture and a test with the client in `tests/client.rs`.
- **`Cargo.toml`** is written by hand. Its API features and the dependencies of the generated code are the
  generator's: `scripts/check_manifest.py` compares them when generating.

Before opening a pull request:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
```

[local-ci](https://github.com/genai-rs/.github/blob/main/docs/local-ci.md) runs the same checks as CI and reports
them on the pull request.
