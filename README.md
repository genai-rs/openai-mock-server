# openai-mock-server

[![crates.io](https://img.shields.io/crates/v/openai-mock-server)](https://crates.io/crates/openai-mock-server)
[![docs.rs](https://img.shields.io/docsrs/openai-mock-server)](https://docs.rs/openai-mock-server)

A scripted mock of the OpenAI API for tests. It serves the API on `127.0.0.1` with an [axum](https://docs.rs/axum)
server generated from [OpenAI's OpenAPI specification](https://github.com/openai/openai-openapi), so requests are
decoded and replies encoded as the specification describes them: a client that sends something else, or a fixture
that does not match its model, fails the test.

The mock shares no code with the client under test, only the specification. Its server and models are generated in
this repository (`src/generated`, from the revision in
[`openapi.revision`](https://github.com/genai-rs/openai-mock-server/blob/main/openapi.revision)); a client such as
[openai-client-base](https://crates.io/crates/openai-client-base) is generated from the same specification in its
own.

```bash
cargo add --dev openai-mock-server
```

```rust,no_run
use openai_mock_server::{fixtures, op, MockServer, Reply, Stream};
use openai_mock_server::server::chat_api::CreateChatCompletionRequest;

# async fn test() {
let mock = MockServer::start().await;
mock.on(op::CREATE_CHAT_COMPLETION)
    .reply(Reply::json(fixtures::chat_completion("Hello!")))
    .reply(Reply::stream(Stream::new(fixtures::chat_chunks(&["Hel", "lo"]))));

// point the client under test at mock.base_url() (http://127.0.0.1:<port>/v1)

let requests = mock.requests::<CreateChatCompletionRequest>();
assert_eq!(requests[0].body.model, "gpt-4o-mini");
assert!(mock.rejected().is_empty());
# }
```

- **Replies**, queued per operation and taken in order, then the `always` reply: JSON, an event stream, bytes, text, an
  SDP answer, an error in OpenAI's envelope (`Reply::error(404, "...")`), a `429` with `retry-after`
  (`Reply::rate_limited`), with extra headers and a delay.
- **Streams** with the wire details clients meet: keep-alive comments, `event:` names on or off, an error after the
  stream started (chat style `data: {"error": ...}` or Responses style `event: error`), no `[DONE]`, a pause between
  events.
- **Fixtures** for the common bodies: chat completions and tool calls, chunks, responses, function calls and their
  events, embeddings, models, files, batches, images, transcriptions, moderations.
- **Recorded requests** as the generated request structs: the decoded body and the headers. Requests that did not
  decode, or that break a validation keyword of the specification (`minimum`, `maxLength`, `pattern`, ...), are
  answered with a `400` and listed by `rejected()`, with the path of each value (`body.dimensions`).
- **Webhooks:** `server::webhooks` sends OpenAI's webhooks to an endpoint of the test, typed
  (`Webhook::ResponseCompleted(...)`) and signed as OpenAI signs them (Standard Webhooks, with
  `StandardWebhooksLayer`); `verify` checks them on the receiving side. The events are the
  models of the `webhook-events` group: enable the `webhook-events-types` feature (or `full`).
- **Served:** chat completions, responses, embeddings, models, files, batches, images, audio, moderations and realtime
  calls (`op::SERVED`). Everything else answers `501`; an operation with no reply scripted too.
- **Cargo features** are the API groups of the generated server. The default ones are the groups the mock scripts
  (it needs them); another group, or `full`, compiles that group's operations too, so their requests are decoded
  before the `501`. The default set keeps a test build short.
- `MockServer::with_api_key` answers `401` to a request without `Authorization: Bearer <key>`.

## License

Licensed under either of [Apache License, Version 2.0](https://github.com/genai-rs/openai-mock-server/blob/main/LICENSE-APACHE) or [MIT license](https://github.com/genai-rs/openai-mock-server/blob/main/LICENSE-MIT) at your
option.
