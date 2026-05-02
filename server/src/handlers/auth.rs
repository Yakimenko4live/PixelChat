use axum::{Json, http::StatusCode};
use bcrypt::{hash, verify, DEFAULT_COST};
use sqlx::PgPool;

use crate::models::{RegisterRequest, LoginRequest, AuthResponse};
use crate::utils::create_token;

pub async fn register(
    pool: &PgPool,
    Json(payload): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let hashed = hash(&payload.password, DEFAULT_COST).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let row = sqlx::query!(
        r#"
        INSERT INTO users (last_name, first_name, patronymic, login, department_id, position, public_key, password_hash, role, is_verified)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'user', false)
        RETURNING id, role, is_verified
        "#,
        payload.last_name,
        payload.first_name,
        payload.patronymic,
        payload.login,
        payload.department_id,
        payload.position,
        payload.public_key,
        hashed
    )
    .fetch_one(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let role_str = row.role.as_deref().unwrap_or("user");
    let token = create_token(row.id, role_str).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(AuthResponse {
        token,
        user_id: row.id,
        role: row.role.unwrap_or_else(|| "user".to_string()),
        is_verified: row.is_verified.unwrap_or(false),
    }))
}

pub async fn login(
    pool: &PgPool,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let row = sqlx::query!(
        r#"
        SELECT id, password_hash, role, is_verified
        FROM users
        WHERE login = $1
        "#,
        payload.login
    )
    .fetch_optional(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let user = row.ok_or(StatusCode::UNAUTHORIZED)?;
    
    let valid = verify(&payload.password, &user.password_hash).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if !valid {
        return Err(StatusCode::UNAUTHORIZED);
    }
    
    let role_str = user.role.as_deref().unwrap_or("user");
    let token = create_token(user.id, role_str).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(AuthResponse {
        token,
        user_id: user.id,
        role: user.role.unwrap_or_else(|| "user".to_string()),
        is_verified: user.is_verified.unwrap_or(false),
    }))
}
