# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.3](https://github.com/genai-rs/openai-mock-server/compare/v0.2.2...v0.2.3) - 2026-11-19

### Added

- validate requests and send webhooks, with openapi-generator-timvw-rust 0.41.0

### Other

- the webhook test needs the webhook-events-types feature

## [0.2.2](https://github.com/genai-rs/openai-mock-server/compare/v0.2.1...v0.2.2) - 2026-11-19

### Added

- regenerate from OpenAI's specification at 16cdf739aee9baa6191cdbab945dd5f7f9920f20

### Other

- the client the mock is tested with is openai-client-base 0.36

## [0.2.1](https://github.com/genai-rs/openai-mock-server/compare/v0.2.0...v0.2.1) - 2026-11-18

### Other

- the client the mock is tested with is openai-client-base 0.35

## [0.2.0](https://github.com/genai-rs/openai-mock-server/compare/v0.1.1...v0.2.0) - 2026-11-18

### Added

- [**breaking**] Unix timestamps are jiff::Timestamps

## [0.1.1](https://github.com/genai-rs/openai-mock-server/compare/v0.1.0...v0.1.1) - 2026-11-18

### Other

- release version 0.1.0

## [0.1.0](https://github.com/genai-rs/openai-mock-server/releases/tag/v0.1.0) - 2026-11-18

### Added

- a scripted mock of the OpenAI API, on a server generated from its specification
