use axum::{
    Router,
    routing::post,
    extract::State,
    Json,
};
use std::sync::Arc;

use crate::handlers::{register, login};
use crate::AppState;

pub fn auth_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/register", post(
            |State(state): State<Arc<AppState>>, Json(payload)| async move {
                register(&state.pool, Json(payload)).await
            }
        ))
        .route("/login", post(
            |State(state): State<Arc<AppState>>, Json(payload)| async move {
                login(&state.pool, Json(payload)).await
            }
        ))
}