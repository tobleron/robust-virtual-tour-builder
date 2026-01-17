use actix_web::{
    Error, HttpResponse,
    body::{BoxBody, EitherBody},
    dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
    web,
};
use futures_util::future::LocalBoxFuture;
use std::future::{Ready, ready};
use std::rc::Rc;

use crate::services::upload_quota::UploadQuotaManager;

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
        // Only check quota for upload endpoints
        let path = req.path().to_string();
        let should_check = path.contains("/media/")
            || path.contains("/project/save")
            || path.contains("/project/import");

        let service = self.service.clone();

        // Extract data needed for check
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
            if should_check {
                if let Some(manager) = quota_manager {
                    // Check if upload can proceed
                    if let Err(e) = manager.can_upload(&ip, content_length).await {
                        tracing::warn!(ip = %ip, size = content_length, error = %e, "Upload rejected");

                        // Construct response using req
                        let res = req.into_response(HttpResponse::TooManyRequests().json(
                            serde_json::json!({
                                "error": "Quota exceeded",
                                "message": e
                            }),
                        ));

                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }

                    // Register upload
                    let _upload_id = manager.register_upload(&ip, content_length).await;

                    // Process request via service
                    let res_call = service.call(req).await;

                    // Unregister upload
                    manager.unregister_upload(&ip, content_length).await;

                    match res_call {
                        Ok(res) => return Ok(res.map_body(|_, b| EitherBody::Left { body: b })),
                        Err(e) => return Err(e),
                    }
                }
            }

            // Proceed normally if no check needed or no manager
            match service.call(req).await {
                Ok(res) => Ok(res.map_body(|_, b| EitherBody::Left { body: b })),
                Err(e) => Err(e),
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_quota_check_middleware_exists() {
        // Validation that middleware struct can be instantiated
        // Real logic tested in upload_quota_tests and integration tests
        let _ = QuotaCheck;
    }
}
