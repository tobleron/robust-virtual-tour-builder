// @efficiency: infra-adapter
use actix_web::web;
use actix_web::{
    Error,
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
};
use futures_util::future::LocalBoxFuture;
use std::future::{Ready, ready};

use crate::metrics::ACTIVE_SESSIONS;
use crate::services::shutdown::ShutdownManager;

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

        let fut = self.service.call(req);

        Box::pin(async move {
            if let Some(manager) = shutdown_manager {
                manager.register_request().await;
                ACTIVE_SESSIONS.inc();
                let res = fut.await;
                ACTIVE_SESSIONS.dec();
                manager.unregister_request().await;
                res
            } else {
                ACTIVE_SESSIONS.inc();
                let res = fut.await;
                ACTIVE_SESSIONS.dec();
                res
            }
        })
    }
}

#[cfg(test)]
mod tests {
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
