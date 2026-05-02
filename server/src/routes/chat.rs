use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Router, Json,
};
use axum::http::StatusCode;
use std::sync::Arc;

use crate::{
    handlers::chat::{get_my_chats, get_chat_messages, send_message},
    models::chat::{SendMessageRequest, GetMessagesQuery, ChatResponse, MessageResponse},
    AppState,
};

// ВРЕМЕННО: позже заменим на получение user_id из JWT через middleware
async fn get_current_user_id() -> i32 {
    // TODO: взять из request extensions
    1
}

pub fn chat_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/chats", get(get_my_chats_handler))
        .route("/chats/{chat_id}/messages", get(get_chat_messages_handler))
        .route("/messages", post(send_message_handler))
}

async fn get_my_chats_handler(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<ChatResponse>>, StatusCode> {
    let user_id = get_current_user_id().await;
    get_my_chats(user_id, &state.pool).await
}

async fn get_chat_messages_handler(
    State(state): State<Arc<AppState>>,
    Path(chat_id): Path<i32>,
    Query(query): Query<GetMessagesQuery>,
) -> Result<Json<Vec<MessageResponse>>, StatusCode> {
    let user_id = get_current_user_id().await;
    get_chat_messages(user_id, chat_id, &state.pool, query).await
}

async fn send_message_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<SendMessageRequest>,
) -> Result<StatusCode, StatusCode> {
    let user_id = get_current_user_id().await;
    send_message(user_id, &state.pool, Json(payload)).await
}