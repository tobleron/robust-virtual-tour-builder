// @efficiency: infra-adapter
use crate::models::user::User;
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
