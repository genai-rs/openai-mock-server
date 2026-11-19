//! What the server generated with `serverValidation` and `serverWebhooks` adds: a request that breaks a validation
//! keyword of the specification is rejected, and a test can send OpenAI's webhooks, signed as OpenAI signs them.
#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

use openai_mock_server::{fixtures, op, MockServer, Reply};
use serde_json::json;

#[tokio::test]
async fn a_request_that_breaks_a_keyword_is_rejected() {
    let mock = MockServer::start().await;
    mock.on(op::CREATE_EMBEDDING)
        .always(Reply::json(fixtures::embeddings(&[&[0.1, 0.2]])));
    let client = reqwest::Client::new();
    let url = format!("{}/embeddings", mock.base_url());

    // `dimensions` has `minimum: 1`
    let response = client
        .post(&url)
        .header("content-type", "application/json")
        .body(
            json!({"model": "text-embedding-3-small", "input": "hi", "dimensions": 0}).to_string(),
        )
        .send()
        .await
        .unwrap();
    assert_eq!(response.status(), 400);
    let rejected = mock.rejected();
    assert_eq!(rejected.len(), 1);
    assert!(rejected[0].contains("body.dimensions"), "{rejected:?}");
    assert_eq!(mock.calls(op::CREATE_EMBEDDING), 0);

    let response = client
        .post(&url)
        .header("content-type", "application/json")
        .body(
            json!({"model": "text-embedding-3-small", "input": "hi", "dimensions": 2}).to_string(),
        )
        .send()
        .await
        .unwrap();
    assert_eq!(response.status(), 200);
}

/// OpenAI's webhook events are the models of the `webhook-events` group: `Webhook` has their variants with
/// `webhook-events-types` (or `full`).
#[cfg(feature = "webhook-events-types")]
mod webhooks {
    use super::*;
    use openai_mock_server::server::webhooks::{
        send, verify, Client, Delivery, StandardWebhooksLayer, Webhook, WebhookEndpoint,
        WebhookSecret,
    };
    use std::sync::{Arc, Mutex};
    use std::time::Duration;

    /// What the receiver got: the headers and the body of each request.
    type Received = Arc<Mutex<Vec<(http::HeaderMap, Vec<u8>)>>>;

    async fn receiver() -> (String, Received) {
        let received: Received = Arc::default();
        let record = received.clone();
        let app = axum::Router::new().fallback(move |request: axum::extract::Request| {
            let record = record.clone();
            async move {
                let headers = request.headers().clone();
                let body = axum::body::to_bytes(request.into_body(), usize::MAX)
                    .await
                    .unwrap()
                    .to_vec();
                record.lock().unwrap().push((headers, body));
                http::StatusCode::OK
            }
        });
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
        (format!("http://{address}/webhooks"), received)
    }

    #[tokio::test]
    async fn a_test_sends_a_signed_webhook() {
        let (url, received) = receiver().await;
        // a test secret, not a credential: whsec_ and base64
        let secret =
            WebhookSecret::new(concat!("whsec", "_", "dGVzdCBzZWNyZXQgZm9yIHRoZSBtb2Nr")).unwrap();
        let client = Client::default().layer(StandardWebhooksLayer::new(secret.clone()));
        let endpoint = WebhookEndpoint::new(url, client).events(["response_completed"]);
        let webhook: Webhook = Webhook::ResponseCompleted(
            serde_json::from_value(json!({
                "id": "evt_1",
                "type": "response.completed",
                "created_at": 1_763_546_400,
                "data": {"id": "resp_1"}
            }))
            .unwrap(),
        );
        assert_eq!(
            send(&endpoint, &webhook).await.unwrap(),
            Delivery::Delivered(http::StatusCode::OK)
        );

        let received = received.lock().unwrap();
        let (headers, body) = &received[0];
        verify(headers, body, &[secret], Duration::from_secs(60)).unwrap();
        let sent: serde_json::Value = serde_json::from_slice(body).unwrap();
        assert_eq!(sent["data"]["id"], "resp_1");
    }
}
