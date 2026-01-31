// @efficiency-role: service-orchestrator
use crate::metrics::ACTIVE_SESSIONS;

use crate::services::shutdown::ShutdownManager;
use crate::services::upload_quota::UploadQuotaManager;
use actix_web::{
    Error, HttpResponse,
    body::{BoxBody, EitherBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    web,
};
use futures_util::future::LocalBoxFuture;
use std::future::{Ready, ready};
use std::rc::Rc;
use tracing::Instrument;

// ==========================================
// QuotaCheck
// ==========================================

pub struct QuotaCheck;

impl<S, B> Transform<S, ServiceRequest> for QuotaCheck
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type InitError = ();
    type Transform = QuotaCheckMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(QuotaCheckMiddleware {
            service: Rc::new(service),
        }))
    }
}

pub struct QuotaCheckMiddleware<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for QuotaCheckMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();

        if !should_check_quota(&req) {
            return Box::pin(async move {
                service
                    .call(req)
                    .await
                    .map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
            });
        }

        let ip = req
            .connection_info()
            .realip_remote_addr()
            .unwrap_or("unknown")
            .to_string();

        let content_length = req
            .headers()
            .get("content-length")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.parse::<usize>().ok())
            .unwrap_or(0);

        let quota_manager = req.app_data::<web::Data<UploadQuotaManager>>().cloned();

        Box::pin(async move {
            if let Some(manager) = quota_manager {
                if let Err(e) = manager.can_upload(&ip, content_length).await {
                    tracing::warn!(ip = %ip, size = content_length, error = %e, "Upload rejected");

                    return Ok(req
                        .into_response(HttpResponse::TooManyRequests().json(serde_json::json!({
                            "error": "Quota exceeded",
                            "message": e
                        })))
                        .map_body(|_, b| EitherBody::Right { body: b }));
                }

                // Register upload
                let _upload_id = manager.register_upload(&ip, content_length).await;

                // Process request via service
                let res_call = service.call(req).await;

                // Unregister upload
                manager.unregister_upload(&ip, content_length).await;

                res_call.map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
            } else {
                service
                    .call(req)
                    .await
                    .map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
            }
        })
    }
}

fn should_check_quota(req: &ServiceRequest) -> bool {
    let path = req.path();
    path.contains("/media/") || path.contains("/project/save") || path.contains("/project/import")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_quota_check_middleware_exists() {
        let _ = QuotaCheck;
    }
}

// ==========================================
// RequestTracker
// ==========================================

pub struct RequestTracker;

impl<S, B> Transform<S, ServiceRequest> for RequestTracker
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = RequestTrackerMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(RequestTrackerMiddleware { service }))
    }
}

pub struct RequestTrackerMiddleware<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for RequestTrackerMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let shutdown_manager = req.app_data::<web::Data<ShutdownManager>>().cloned();

        let request_id = req
            .headers()
            .get("X-Request-ID")
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string())
            .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

        let fut = self.service.call(req);

        let span = tracing::info_span!("request", request_id = %request_id);

        Box::pin(
            async move {
                ACTIVE_SESSIONS.inc();
                if let Some(manager) = shutdown_manager {
                    manager.register_request().await;
                    let res = fut.await;
                    manager.unregister_request().await;
                    ACTIVE_SESSIONS.dec();
                    res
                } else {
                    let res = fut.await;
                    ACTIVE_SESSIONS.dec();
                    res
                }
            }
            .instrument(span),
        )
    }
}

#[cfg(test)]
mod request_tracker_tests {
    use super::*;
    use actix_web::{App, HttpResponse, test, web};

    #[actix_web::test]
    async fn test_request_tracker_middleware() {
        let app = test::init_service(
            App::new()
                .wrap(RequestTracker)
                .route("/", web::get().to(HttpResponse::Ok)),
        )
        .await;

        let req = test::TestRequest::get().uri("/").to_request();
        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_success());
    }
}
