use axum::{
    extract::{Query, State},
    routing::get,
    Router,
};
use std::sync::Arc;

use crate::handlers::ws::ws_handler;
use crate::AppState;

pub fn ws_routes() -> Router<Arc<AppState>> {
    Router::new().route("/ws", get(ws_handler))
}