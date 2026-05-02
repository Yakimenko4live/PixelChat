use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub last_name: String,
    pub first_name: String,
    pub patronymic: Option<String>,
    pub login: String,
    pub department_id: i32,
    pub position: String,
    pub public_key: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub login: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user_id: i32,
    pub role: String,
    pub is_verified: bool,
}