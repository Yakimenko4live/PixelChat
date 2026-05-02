use dotenv::dotenv;
use std::env;

pub struct Config {
    pub database_url: String,
    pub server_port: u16,
    pub jwt_secret: String,
}

impl Config {
    pub fn from_env() -> Self {
        dotenv().ok();
        
        Self {
            database_url: env::var("DATABASE_URL").expect("DATABASE_URL must be set"),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()
                .expect("SERVER_PORT must be a number"),
            jwt_secret: env::var("JWT_SECRET").expect("JWT_SECRET must be set"),
        }
    }
}