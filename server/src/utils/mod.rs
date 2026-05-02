use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Serialize, Deserialize};
use std::env;
use chrono::{Utc, Duration};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: i32,
    pub role: String,
    pub exp: usize,
}

pub mod jwt {
    use super::*;
    
    pub fn create_token(user_id: i32, role: &str) -> Result<String, jsonwebtoken::errors::Error> {
        let secret = env::var("JWT_SECRET").expect("JWT_SECRET not set");
        let expiration = Utc::now()
            .checked_add_signed(Duration::days(7))
            .expect("valid timestamp")
            .timestamp();
        
        let claims = Claims {
            sub: user_id,
            role: role.to_string(),
            exp: expiration as usize,
        };
        
        encode(&Header::default(), &claims, &EncodingKey::from_secret(secret.as_bytes()))
    }
}

// Реэкспорт для удобства
pub use jwt::create_token;
