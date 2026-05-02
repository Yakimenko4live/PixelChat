use axum::{
    Router,
    routing::get,
    extract::State,
};
use std::sync::Arc;

use crate::handlers::get_departments;
use crate::AppState;

pub fn department_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/departments", get(
            |State(state): State<Arc<AppState>>| async move {
                get_departments(&state.pool).await
            }
        ))
}