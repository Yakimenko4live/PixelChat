use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct DepartmentResponse {
    pub id: i32,
    pub name: String,
    pub type_: String,
    pub parent_id: Option<i32>,
}