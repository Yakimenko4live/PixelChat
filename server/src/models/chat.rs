use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
pub struct ChatResponse {
    pub chat_id: i32,
    pub chat_type: String,
    pub name: String,
    pub avatar_url: Option<String>,
    pub last_message: Option<String>,
    pub last_message_time: Option<chrono::DateTime<chrono::Utc>>,
    pub unread_count: i64,
}

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub id: i32,
    pub sender_id: i32,
    pub sender_name: String,
    pub encrypted_content: Option<String>,
    pub encrypted_media_url: Option<String>,
    pub media_type: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub is_read: bool,
}

#[derive(Debug, Deserialize)]
pub struct SendMessageRequest {
    pub chat_type: String,
    pub chat_id: Option<i32>,
    pub receiver_id: Option<i32>,
    pub encrypted_content: String,
}

#[derive(Debug, Deserialize)]
pub struct GetMessagesQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}