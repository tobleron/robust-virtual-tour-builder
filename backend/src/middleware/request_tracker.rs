use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use futures_util::future::LocalBoxFuture;
use std::future::{ready, Ready};
use actix_web::web;

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
                let res = fut.await;
                manager.unregister_request().await;
                res
            } else {
                fut.await
            }
        })
    }
}
