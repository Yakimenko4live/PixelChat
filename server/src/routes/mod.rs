mod auth;
mod department;
mod chat;
mod ws;

pub use auth::auth_routes;
pub use department::department_routes;
pub use chat::chat_routes;
pub use ws::ws_routes;