pub mod auth {
    // @efficiency: infra-adapter
    use crate::models::User;
    use crate::services::auth::jwt::decode_token;
    use actix_web::{
        Error, HttpMessage, HttpResponse,
        body::{BoxBody, EitherBody},
        dev::{Service, ServiceRequest, ServiceResponse, Transform, forward_ready},
        http::header,
        web,
    };
    use futures_util::future::LocalBoxFuture;
    use sqlx::SqlitePool;
    use std::future::{Ready, ready};
    use std::rc::Rc;

    pub struct AuthMiddleware;

    impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
    where
        S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
        S::Future: 'static,
        B: 'static,
    {
        type Response = ServiceResponse<EitherBody<B, BoxBody>>;
        type Error = Error;
        type InitError = ();
        type Transform = AuthMiddlewareMiddleware<S>;
        type Future = Ready<Result<Self::Transform, Self::InitError>>;

        fn new_transform(&self, service: S) -> Self::Future {
            ready(Ok(AuthMiddlewareMiddleware {
                service: Rc::new(service),
            }))
        }
    }

    pub struct AuthMiddlewareMiddleware<S> {
        service: Rc<S>,
    }

    impl<S, B> Service<ServiceRequest> for AuthMiddlewareMiddleware<S>
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

            Box::pin(async move {
                // Check Authorization header
                let auth_header = req.headers().get(header::AUTHORIZATION);

                let token_str = if let Some(header) = auth_header {
                    match header.to_str() {
                        Ok(header_str) => {
                            if header_str.starts_with("Bearer ") {
                                Some(header_str[7..].to_string())
                            } else {
                                None
                            }
                        }
                        Err(_) => None,
                    }
                } else {
                    None
                };

                let token = if let Some(t) = token_str {
                    t
                } else {
                    // Try query param
                    let qs = req.query_string();
                    let mut found = None;
                    for pair in qs.split('&') {
                        if let Some((key, value)) = pair.split_once('=') {
                            if key == "token" {
                                found = Some(value.to_string());
                                break;
                            }
                        }
                    }

                    if let Some(t) = found {
                        t
                    } else {
                        let res = req.into_response(HttpResponse::Unauthorized().json(
                            serde_json::json!({"error": "Missing Authorization header or token param"}),
                        ));
                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }
                };

                // Validate token
                let claims = match decode_token(&token) {
                    Ok(claims) => claims,
                    Err(e) => {
                        let res = req.into_response(
                            HttpResponse::Unauthorized()
                                .json(serde_json::json!({"error": e.to_string()})),
                        );
                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }
                };

                // Fetch user from DB
                let pool = match req.app_data::<web::Data<SqlitePool>>() {
                    Some(p) => p,
                    None => {
                        tracing::error!("Database pool not found in app_data");
                        let res = req.into_response(HttpResponse::InternalServerError().finish());
                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }
                };

                // We use SQLx to find the user
                let user_result = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
                    .bind(&claims.sub)
                    .fetch_optional(pool.get_ref())
                    .await;

                match user_result {
                    Ok(Some(user)) => {
                        // Attach user to request extensions
                        req.extensions_mut().insert(user);
                    }
                    Ok(None) => {
                        let res = req.into_response(
                            HttpResponse::Unauthorized()
                                .json(serde_json::json!({"error": "User not found"})),
                        );
                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }
                    Err(e) => {
                        tracing::error!("Database error during auth: {}", e);
                        let res = req.into_response(
                            HttpResponse::InternalServerError()
                                .json(serde_json::json!({"error": "Database error"})),
                        );
                        return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                    }
                }

                // Continue request
                let res = service.call(req).await?;
                Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
            })
        }
    }
}

pub mod quota_check {
    // @efficiency: infra-adapter
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
                if should_check && let Some(manager) = quota_manager {
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
}

pub mod request_tracker {
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
}
