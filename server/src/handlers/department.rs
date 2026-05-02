use axum::{Json, http::StatusCode};
use sqlx::PgPool;

use crate::models::DepartmentResponse;

pub async fn get_departments(
    pool: &PgPool,
) -> Result<Json<Vec<DepartmentResponse>>, StatusCode> {
    let rows = sqlx::query!(
        r#"
        SELECT id, name, type as type_, parent_id
        FROM departments
        ORDER BY id
        "#,
    )
    .fetch_all(pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let departments = rows
        .into_iter()
        .map(|row| DepartmentResponse {
            id: row.id,
            name: row.name,
            type_: row.type_.to_string(),
            parent_id: row.parent_id,
        })
        .collect();
    
    Ok(Json(departments))
}