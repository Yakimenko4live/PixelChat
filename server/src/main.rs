use axum::Router;
use std::sync::Arc;
use sqlx::PgPool;
use std::net::SocketAddr;
use std::collections::HashMap;
use tokio::sync::Mutex;
use tokio::sync::mpsc::UnboundedSender;
use axum::extract::ws::Message;

mod handlers;
mod models;
mod routes;
mod config;
mod middleware;
mod utils;

pub struct AppState {
    pub pool: PgPool,
    pub sessions: Arc<Mutex<HashMap<i32, UnboundedSender<Message>>>>,
}

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();
    
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPool::connect(&database_url).await.expect("Failed to connect to database");
    
    let sessions: Arc<Mutex<HashMap<i32, UnboundedSender<Message>>>> = Arc::new(Mutex::new(HashMap::new()));
    
    let app_state = Arc::new(AppState {
        pool: pool.clone(),
        sessions: sessions.clone(),
    });
    
    // Объединяем роутеры через merge вместо nest для корневого
    let app = Router::new()
        .nest("/api/auth", routes::auth_routes())
        .nest("/api/departments", routes::department_routes())
        .nest("/api", routes::chat_routes())
        .merge(routes::ws_routes())  // <- используем merge вместо nest для ws
        .with_state(app_state);
    
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Server running on http://{}", addr);
    
    axum::serve(tokio::net::TcpListener::bind(addr).await.unwrap(), app)
        .await
        .unwrap();
}