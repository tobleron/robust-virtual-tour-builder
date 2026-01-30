pub mod auth {
    // @efficiency: infra-adapter
    use crate::models::User;
    use crate::services::auth::jwt::decode_token;
    use actix_web::{
        body::{BoxBody, EitherBody},
        dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
        http::header,
        web, Error, HttpMessage, HttpResponse,
    };
    use futures_util::future::LocalBoxFuture;
    use sqlx::SqlitePool;
    use std::future::{ready, Ready};
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
                let token = match extract_token(&req) {
                    Some(t) => t,
                    None => {
                        return Ok(req
                            .into_response(HttpResponse::Unauthorized().json(serde_json::json!({
                                "error": "Missing Authorization header or token param"
                            })))
                            .map_body(|_, b| EitherBody::Right { body: b }));
                    }
                };

                // Validate token
                let claims = match decode_token(&token) {
                    Ok(claims) => claims,
                    Err(e) => {
                        return Ok(req
                            .into_response(HttpResponse::Unauthorized().json(serde_json::json!({
                                "error": e.to_string()
                            })))
                            .map_body(|_, b| EitherBody::Right { body: b }));
                    }
                };

                // Fetch user from DB
                if let Err(response) = attach_user_to_request(&req, &claims.sub).await {
                    let res = req.into_response(response);
                    return Ok(res.map_body(|_, b| EitherBody::Right { body: b }));
                }

                // Continue request
                let res = service.call(req).await?;
                Ok(res.map_body(|_, b| EitherBody::Left { body: b }))
            })
        }
    }

    fn extract_token(req: &ServiceRequest) -> Option<String> {
        // Check Authorization header
        if let Some(header) = req.headers().get(header::AUTHORIZATION) {
            if let Ok(header_str) = header.to_str() {
                if header_str.starts_with("Bearer ") {
                    return Some(header_str[7..].to_string());
                }
            }
        }

        // Try query param
        req.query_string().split('&').find_map(|pair| {
            let (key, value) = pair.split_once('=')?;
            if key == "token" {
                Some(value.to_string())
            } else {
                None
            }
        })
    }

    async fn attach_user_to_request(req: &ServiceRequest, user_id: &str) -> Result<(), HttpResponse> {
        let pool = match req.app_data::<web::Data<SqlitePool>>() {
            Some(p) => p,
            None => {
                tracing::error!("Database pool not found in app_data");
                return Err(HttpResponse::InternalServerError().finish());
            }
        };

        let user_result = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
            .bind(user_id)
            .fetch_optional(pool.get_ref())
            .await;

        match user_result {
            Ok(Some(user)) => {
                req.extensions_mut().insert(user);
                Ok(())
            }
            Ok(None) => Err(HttpResponse::Unauthorized()
                .json(serde_json::json!({"error": "User not found"}))),
            Err(e) => {
                tracing::error!("Database error during auth: {}", e);
                Err(HttpResponse::InternalServerError()
                    .json(serde_json::json!({"error": "Database error"})))
            }
        }
    }
}

pub mod quota_check {
    // @efficiency: infra-adapter
    use crate::services::upload_quota::UploadQuotaManager;
    use actix_web::{
        body::{BoxBody, EitherBody},
        dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
        web, Error, HttpResponse,
    };
    use futures_util::future::LocalBoxFuture;
    use std::future::{ready, Ready};
    use std::rc::Rc;

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
            let path = req.path().to_string();
            let should_check = path.contains("/media/")
                || path.contains("/project/save")
                || path.contains("/project/import");

            let service = self.service.clone();

            if !should_check {
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
                    // Check if upload can proceed
                    if let Err(e) = manager.can_upload(&ip, content_length).await {
                        tracing::warn!(ip = %ip, size = content_length, error = %e, "Upload rejected");

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
                        Ok(res) => Ok(res.map_body(|_, b| EitherBody::Left { body: b })),
                        Err(e) => Err(e),
                    }
                } else {
                    // No manager, proceed
                    service
                        .call(req)
                        .await
                        .map(|res| res.map_body(|_, b| EitherBody::Left { body: b }))
                }
            })
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_quota_check_middleware_exists() {
            let _ = QuotaCheck;
        }
    }
}

pub mod request_tracker {
    // @efficiency: infra-adapter
    use crate::metrics::ACTIVE_SESSIONS;
    use crate::services::shutdown::ShutdownManager;
    use actix_web::{
        dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
        web, Error,
    };
    use futures_util::future::LocalBoxFuture;
    use std::future::{ready, Ready};

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
        use actix_web::{test, web, App, HttpResponse};

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
