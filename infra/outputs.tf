output "dbt_sa_email" {
  description = "dbt 実行 SA のメールアドレス"
  value       = google_service_account.dbt.email
}

output "artifacts_bucket_name" {
  description = "dbt アーティファクト用 GCS バケット名"
  value       = google_storage_bucket.dbt_artifacts.name
}

output "docs_bucket_name" {
  description = "dbt docs ホスティング用 GCS バケット名"
  value       = google_storage_bucket.dbt_docs.name
}
