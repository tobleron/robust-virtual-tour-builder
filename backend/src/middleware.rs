// @efficiency-role: service-orchestrator
use crate::api::utils::json_error_response;
use crate::metrics::ACTIVE_SESSIONS;

use crate::services::shutdown::ShutdownManager;
use crate::services::upload_quota::UploadQuotaManager;
use actix_web::{
    Error,
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

        let ip_raw = req
            .connection_info()
            .realip_remote_addr()
            .unwrap_or("unknown")
            .to_string();

        // Normalize: strip port if present (handles IPv4 and some header formats)
        // Note: realip_remote_addr usually provides just the IP, but we ensure consistency here.
        let ip = ip_raw.split(':').next().unwrap_or("unknown").to_string();

        let content_length = req
            .headers()
            .get("content-length")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.parse::<usize>().ok())
            .unwrap_or(0);

        let quota_manager = req.app_data::<web::Data<UploadQuotaManager>>().cloned();

        Box::pin(async move {
            if let Some(manager) = quota_manager {
                match manager.try_register_upload(&ip, content_length).await {
                    Err(e) => {
                        tracing::warn!(ip = %ip, size = content_length, error = %e, "Upload rejected");

                        Ok(req
                            .into_response(json_error_response(
                                actix_web::http::StatusCode::TOO_MANY_REQUESTS,
                                "Quota exceeded",
                                &e,
                                None,
                            ))
                            .map_body(|_, b| EitherBody::Right { body: b }))
                    }
                    Ok(_upload_id) => {
                        // Process request via service
                        let res_call = service.call(req).await;

                        // Unregister upload
                        manager.unregister_upload(&ip, content_length).await;

                        res_call.map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
                    }
                }
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
    path.contains("/media/")
        || path.contains("/project/save")
        || path.contains("/project/import")
        || path.contains("/project/create-tour-package")
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::test;

    #[actix_web::test]
    async fn test_quota_check_middleware_exists() {
        let _ = QuotaCheck;
    }

    #[actix_web::test]
    async fn test_should_check_quota_paths() {
        let req = test::TestRequest::post()
            .uri("/api/media/upload")
            .to_srv_request();
        assert!(should_check_quota(&req));

        let req = test::TestRequest::post()
            .uri("/api/project/save")
            .to_srv_request();
        assert!(should_check_quota(&req));

        let req = test::TestRequest::get().uri("/health").to_srv_request();
        assert!(!should_check_quota(&req));
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
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
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
    type Response = ServiceResponse<EitherBody<B, BoxBody>>;
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

        if let Some(manager) = &shutdown_manager
            && manager.is_shutting_down()
        {
            return Box::pin(async move {
                Ok(req
                    .into_response(json_error_response(
                        actix_web::http::StatusCode::SERVICE_UNAVAILABLE,
                        "Service Unavailable",
                        "Server is shutting down. Please retry shortly.",
                        Some(&request_id),
                    ))
                    .map_body(|_, b| EitherBody::Right { body: b }))
            });
        }

        let fut = self.service.call(req);

        let span = tracing::info_span!("request", request_id = %request_id);

        Box::pin(
            async move {
                if let Some(m) = &*ACTIVE_SESSIONS {
                    m.inc();
                }
                if let Some(manager) = shutdown_manager {
                    manager.register_request().await;
                    let res = fut.await;
                    manager.unregister_request().await;
                    if let Some(m) = &*ACTIVE_SESSIONS {
                        m.dec();
                    }
                    res.map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
                } else {
                    let res = fut.await;
                    if let Some(m) = &*ACTIVE_SESSIONS {
                        m.dec();
                    }
                    res.map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
                }
            }
            .instrument(span),
        )
    }
}

#[cfg(test)]
mod request_tracker_tests {
    use super::*;
    use crate::services::shutdown::ShutdownManager;
    use actix_web::{App, HttpResponse, http::StatusCode, test, web};
    use std::time::Duration;

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

    #[actix_web::test]
    async fn test_request_tracker_rejects_when_shutdown_started() {
        let shutdown = web::Data::new(ShutdownManager::new(Duration::from_secs(1)));
        shutdown.begin_shutdown();

        let app = test::init_service(
            App::new()
                .app_data(shutdown)
                .wrap(RequestTracker)
                .route("/", web::get().to(HttpResponse::Ok)),
        )
        .await;

        let req = test::TestRequest::get().uri("/").to_request();
        let resp = test::call_service(&app, req).await;

        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);
    }

    #[actix_web::test]
    async fn test_request_tracker_drains_on_error_response() {
        let shutdown = web::Data::new(ShutdownManager::new(Duration::from_secs(1)));
        let shutdown_ref = shutdown.clone();

        let app = test::init_service(App::new().app_data(shutdown).wrap(RequestTracker).route(
            "/",
            web::get().to(|| async { HttpResponse::InternalServerError().finish() }),
        ))
        .await;

        let req = test::TestRequest::get().uri("/").to_request();
        let resp = test::call_service(&app, req).await;

        assert_eq!(resp.status(), StatusCode::INTERNAL_SERVER_ERROR);
        assert_eq!(shutdown_ref.active_count().await, 0);
    }
}
