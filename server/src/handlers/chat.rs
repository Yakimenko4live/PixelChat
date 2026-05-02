use axum::{Json, http::StatusCode};
use sqlx::PgPool;

use crate::models::chat::{ChatResponse, MessageResponse, GetMessagesQuery, SendMessageRequest};
use chrono::{Utc, DateTime};

pub async fn get_my_chats(
    user_id: i32,
    pool: &PgPool,
) -> Result<Json<Vec<ChatResponse>>, StatusCode> {
    let rows = sqlx::query!(
        r#"
        WITH last_messages AS (
            SELECT DISTINCT ON (chat_id) 
                m.chat_id,
                m.encrypted_content as content,
                m.created_at,
                m.is_read
            FROM messages m
            JOIN chat_members cm ON m.chat_id = cm.chat_id
            WHERE cm.user_id = $1
            ORDER BY m.chat_id, m.created_at DESC
        )
        SELECT 
            c.id as chat_id,
            c.chat_type,
            COALESCE(c.name, 
                CASE 
                    WHEN c.chat_type = 'private' THEN (
                        SELECT u.first_name || ' ' || u.last_name
                        FROM chat_members cm
                        JOIN users u ON cm.user_id = u.id
                        WHERE cm.chat_id = c.id AND cm.user_id != $1
                        LIMIT 1
                    )
                    ELSE 'Group Chat'
                END
            ) as name,
            c.avatar_url,
            lm.content as last_message,
            lm.created_at as last_message_time,
            COALESCE((
                SELECT COUNT(*)
                FROM messages m2
                WHERE m2.chat_id = c.id 
                AND m2.sender_id != $1
                AND m2.is_read = false
            ), 0) as unread_count
        FROM chats c
        LEFT JOIN last_messages lm ON c.id = lm.chat_id
        WHERE c.id IN (
            SELECT chat_id FROM chat_members WHERE user_id = $1
        )
        ORDER BY lm.created_at DESC NULLS LAST
        "#,
        user_id
    )
    .fetch_all(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
let chats = rows
    .into_iter()
    .map(|row| ChatResponse {
        chat_id: row.chat_id,
        chat_type: row.chat_type,
        name: row.name.unwrap_or_else(|| "Chat".to_string()),
        avatar_url: row.avatar_url,
        last_message: Some(row.last_message),  // <-- оберни в Some
        last_message_time: row.last_message_time.map(|dt| DateTime::<Utc>::from_naive_utc_and_offset(dt, Utc)),
        unread_count: row.unread_count.unwrap_or(0),
    })
    .collect();
    
    Ok(Json(chats))
}

pub async fn get_chat_messages(
    user_id: i32,
    chat_id: i32,
    pool: &PgPool,
    query: GetMessagesQuery,
) -> Result<Json<Vec<MessageResponse>>, StatusCode> {
    let limit = query.limit.unwrap_or(50);
    let offset = query.offset.unwrap_or(0);
    
    // Проверяем, что пользователь состоит в чате
    let is_member = sqlx::query_scalar!(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM chat_members 
            WHERE chat_id = $1 AND user_id = $2
        )
        "#,
        chat_id,
        user_id
    )
    .fetch_one(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .unwrap_or(false);
    
    if !is_member {
        return Err(StatusCode::FORBIDDEN);
    }
    
    // Получаем тип чата
    let chat_type = sqlx::query_scalar!(
        r#"
        SELECT chat_type FROM chats WHERE id = $1
        "#,
        chat_id
    )
    .fetch_one(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let messages = if chat_type == "private" {
        let rows = sqlx::query!(
            r#"
            SELECT 
                m.id,
                m.sender_id,
                m.encrypted_content,
                m.encrypted_media_url,
                m.media_type,
                m.created_at,
                m.is_read,
                u.first_name as user_first_name,
                u.last_name as user_last_name
            FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE m.chat_id = $1
            ORDER BY m.created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            chat_id,
            limit,
            offset
        )
        .fetch_all(pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        rows.into_iter()
            .map(|row| MessageResponse {
                id: row.id,
                sender_id: row.sender_id.unwrap_or(0),
                sender_name: format!("{} {}", row.user_first_name, row.user_last_name),
                encrypted_content: Some(row.encrypted_content),
                encrypted_media_url: row.encrypted_media_url,
                media_type: row.media_type,
                created_at: row.created_at.map(|dt| DateTime::<Utc>::from_naive_utc_and_offset(dt, Utc)).unwrap_or_else(|| Utc::now()),
                is_read: row.is_read.unwrap_or(false),
            })
            .collect()
    } else {
        let rows = sqlx::query!(
            r#"
            SELECT 
                gm.id,
                gm.sender_id,
                gm.encrypted_content,
                gm.encrypted_media_url,
                gm.media_type,
                gm.created_at,
                u.first_name as user_first_name,
                u.last_name as user_last_name
            FROM group_messages gm
            JOIN users u ON gm.sender_id = u.id
            WHERE gm.chat_id = $1
            ORDER BY gm.created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            chat_id,
            limit,
            offset
        )
        .fetch_all(pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        rows.into_iter()
            .map(|row| MessageResponse {
                id: row.id,
                sender_id: row.sender_id.unwrap_or(0),
                sender_name: format!("{} {}", row.user_first_name, row.user_last_name),
                encrypted_content: Some(row.encrypted_content),
                encrypted_media_url: row.encrypted_media_url,
                media_type: row.media_type,
                created_at: row.created_at.map(|dt| DateTime::<Utc>::from_naive_utc_and_offset(dt, Utc)).unwrap_or_else(|| Utc::now()),
                is_read: false,
            })
            .collect()
    };
    
    Ok(Json(messages))
}

pub async fn send_message(
    user_id: i32,
    pool: &PgPool,
    Json(payload): Json<SendMessageRequest>,
) -> Result<StatusCode, StatusCode> {
    let chat_id = if payload.chat_type == "private" {
        let receiver_id = payload.receiver_id.ok_or(StatusCode::BAD_REQUEST)?;
        
        // Получаем или создаем чат
        let result = sqlx::query_scalar!(
            r#"
            SELECT get_or_create_private_chat($1, $2)
            "#,
            user_id,
            receiver_id
        )
        .fetch_one(pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        result.ok_or(StatusCode::INTERNAL_SERVER_ERROR)?
    } else {
        payload.chat_id.ok_or(StatusCode::BAD_REQUEST)?
    };
    
    sqlx::query!(
        r#"
        INSERT INTO messages (chat_id, sender_id, encrypted_content, created_at)
        VALUES ($1, $2, $3, $4)
        "#,
        chat_id,
        user_id,
        payload.encrypted_content,
        Utc::now().naive_utc()
    )
    .execute(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(StatusCode::CREATED)
}