# ---------------------------------------------------------------------------
# Service Account: dbt 実行用 SA
# ---------------------------------------------------------------------------
resource "google_service_account" "dbt" {
  project      = local.config.project_id
  account_id   = "${local.prefix}-dbt"
  display_name = "dbt SA (${var.env})"
  labels       = local.common_labels
}

# GitHub Actions（WIF）が dbt SA を直接使用できるよう Workload Identity User 権限を付与
resource "google_service_account_iam_member" "dbt_wi_user" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.workloadIdentityUser"
  member             = var.wif_principal
}

# ---------------------------------------------------------------------------
# BigQuery IAM
# ---------------------------------------------------------------------------

# dbt SA にプロジェクトレベルの BigQuery Job User を付与（クエリ実行に必要）
resource "google_project_iam_member" "dbt_bq_job_user" {
  project = local.config.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

# dbt SA にプロジェクトレベルの BigQuery Data Editor を付与（全データセットへの読み書きに必要）
resource "google_project_iam_member" "dbt_bq_data_editor" {
  project = local.config.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

# ---------------------------------------------------------------------------
# GCS: dbt アーティファクト用バケット（manifest.json・catalog.json 等）
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "dbt_artifacts" {
  project                     = local.config.project_id
  name                        = "${local.prefix}-dbt-artifacts"
  location                    = local.config.location
  uniform_bucket_level_access = true
  force_destroy               = false
  labels                      = local.common_labels

  versioning {
    enabled = true
  }
}

# dbt SA にアーティファクトバケットの Object Admin 権限を付与
resource "google_storage_bucket_iam_member" "dbt_artifacts_admin" {
  bucket = google_storage_bucket.dbt_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dbt.email}"
}

# ---------------------------------------------------------------------------
# GCS: dbt docs ホスティング用バケット（dbt docs generate の出力先）
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "dbt_docs" {
  project                     = local.config.project_id
  name                        = "${local.prefix}-dbt-docs"
  location                    = local.config.location
  uniform_bucket_level_access = true
  force_destroy               = false
  labels                      = local.common_labels
}

# dbt SA に docs バケットの Object Admin 権限を付与（ドキュメントのアップロードに必要）
resource "google_storage_bucket_iam_member" "dbt_docs_admin" {
  bucket = google_storage_bucket.dbt_docs.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dbt.email}"
}
