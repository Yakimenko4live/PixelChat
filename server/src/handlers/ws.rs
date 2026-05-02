use axum::{
    extract::{
        ws::{WebSocket, WebSocketUpgrade, Message},
        State,
        Query,
    },
    response::{IntoResponse, Response},
    http::StatusCode,
};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use futures::stream::{SplitSink, SplitStream};
use futures::{SinkExt, StreamExt};
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use crate::utils::Claims;
use crate::AppState;

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    Query(params): Query<HashMap<String, String>>,
    State(state): State<Arc<AppState>>,
) -> Response {
    let token = match params.get("token") {
        Some(t) => t,
        None => return (StatusCode::UNAUTHORIZED, "Missing token").into_response(),
    };
    
    let secret = std::env::var("JWT_SECRET").unwrap();
    let token_data = match decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    ) {
        Ok(data) => data,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Invalid token").into_response(),
    };
    
    let user_id = token_data.claims.sub;
    let sessions = state.sessions.clone();
    
    ws.on_upgrade(move |socket| handle_socket(socket, user_id, sessions))
}

async fn handle_socket(socket: WebSocket, user_id: i32, state: Arc<Mutex<HashMap<i32, tokio::sync::mpsc::UnboundedSender<Message>>>>) {
    let (mut sender, mut receiver) = socket.split();
    
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel();
    
    {
        let mut map = state.lock().await;
        map.insert(user_id, tx);
    }
    
    let mut send_task = tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            if sender.send(msg).await.is_err() {
                break;
            }
        }
    });
    
    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            match msg {
                Message::Text(text) => {
                    println!("Received from user {}: {}", user_id, text);
                }
                _ => {}
            }
        }
    });
    
    tokio::select! {
        _ = &mut send_task => recv_task.abort(),
        _ = &mut recv_task => send_task.abort(),
    }
    
    let mut map = state.lock().await;
    map.remove(&user_id);
}