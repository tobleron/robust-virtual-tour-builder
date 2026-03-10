// @efficiency-role: infra-adapter
use std::rc::Rc;

use actix_web::{
    Error,
    body::{BoxBody, EitherBody, MessageBody},
    dev::{Service, ServiceRequest, ServiceResponse},
    http::{
        StatusCode,
        header::{CONTENT_TYPE, HeaderName, HeaderValue},
    },
};
use futures_util::future::LocalBoxFuture;
use serde_json::json;

use crate::startup;

pub(super) fn call<S, B>(
    service: Rc<S>,
    scope: Rc<String>,
    req: ServiceRequest,
) -> LocalBoxFuture<'static, Result<ServiceResponse<EitherBody<B, BoxBody>>, Error>>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: MessageBody + 'static,
{
    let request_id = req
        .headers()
        .get("X-Request-ID")
        .and_then(|header| header.to_str().ok())
        .map(|value| value.to_string());

    Box::pin(async move {
        let res = service.call(req).await?;
        let (_, scope_burst) = startup::rate_limit_settings_for_class(scope.as_str());

        if res.status() == StatusCode::TOO_MANY_REQUESTS {
            return Ok(rate_limited_response(
                res,
                scope.as_str(),
                scope_burst,
                request_id,
            ));
        }

        Ok(success_response(res, scope.as_str(), scope_burst))
    })
}

fn rate_limited_response<B>(
    res: ServiceResponse<B>,
    scope: &str,
    scope_burst: u32,
    request_id: Option<String>,
) -> ServiceResponse<EitherBody<B, BoxBody>>
where
    B: MessageBody + 'static,
{
    let retry_after = res
        .headers()
        .get("Retry-After")
        .and_then(|header| header.to_str().ok())
        .and_then(|value| value.parse::<u64>().ok())
        .unwrap_or(0);

    let mut msg = json!({
        "code": "RATE_LIMITED",
        "reason": "rate_limit_exceeded",
        "retryAfterSec": retry_after,
        "scope": scope,
        "message": "Too many requests. Please try again later."
    });

    if let Some(request_id) = request_id.as_ref()
        && let Some(obj) = msg.as_object_mut()
    {
        obj.insert("requestId".to_string(), json!(request_id));
    }

    let session_id = res
        .request()
        .headers()
        .get("x-session-id")
        .and_then(|header| header.to_str().ok())
        .map(|value| value.to_string())
        .or_else(|| {
            res.request()
                .cookie("id")
                .map(|cookie| cookie.value().to_string())
        })
        .unwrap_or_else(|| "anon".to_string());

    tracing::warn!(
        module = "RateLimiter",
        scope,
        retry_after,
        session_id = %session_id,
        request_id = ?request_id,
        "RATE_LIMIT_EXCEEDED"
    );

    let new_body = serde_json::to_string(&msg).unwrap_or_else(|_| "{}".to_string());
    let mut res = res.map_body(|_, _| EitherBody::Right {
        body: BoxBody::new(new_body),
    });

    res.headers_mut()
        .insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

    apply_rate_limit_headers(&mut res, scope, scope_burst, retry_after, true);
    res
}

fn success_response<B>(
    res: ServiceResponse<B>,
    scope: &str,
    scope_burst: u32,
) -> ServiceResponse<EitherBody<B, BoxBody>>
where
    B: MessageBody + 'static,
{
    let mut res = res.map_body(|_, body| EitherBody::Left { body });
    apply_rate_limit_headers(&mut res, scope, scope_burst, 0, false);
    res
}

fn apply_rate_limit_headers<B>(
    res: &mut ServiceResponse<EitherBody<B, BoxBody>>,
    scope: &str,
    scope_burst: u32,
    retry_after: u64,
    exhausted: bool,
) where
    B: MessageBody + 'static,
{
    if exhausted && retry_after > 0 && !res.headers().contains_key("x-ratelimit-after") {
        if let Ok(value) = HeaderValue::from_str(&retry_after.to_string()) {
            res.headers_mut()
                .insert(HeaderName::from_static("x-ratelimit-after"), value);
        }
    }

    if let Ok(value) = HeaderValue::from_str(scope) {
        res.headers_mut()
            .insert(HeaderName::from_static("x-ratelimit-scope"), value);
    }
    if let Ok(value) = HeaderValue::from_str(&scope_burst.to_string()) {
        res.headers_mut()
            .insert(HeaderName::from_static("x-ratelimit-limit"), value.clone());
        res.headers_mut().insert(
            HeaderName::from_static("x-ratelimit-remaining"),
            if exhausted {
                HeaderValue::from_static("0")
            } else {
                value
            },
        );
    }
    if exhausted && let Ok(value) = HeaderValue::from_str(&retry_after.to_string()) {
        res.headers_mut().insert(
            HeaderName::from_static("x-ratelimit-class-retry-after"),
            value,
        );
    }
}
