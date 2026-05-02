mod auth;
mod department;
pub mod ws;
pub mod chat;

pub use auth::{register, login};
pub use department::get_departments;
pub use ws::ws_handler;
pub use chat::{get_my_chats, get_chat_messages, send_message};