locals {
  config = var.environments[var.env]
  prefix = var.env == "prd" ? var.client_name : "${var.client_name}-${var.env}"
}

# ---------------------------------------------------------------------------
# リモートステート: {client}-infra リポジトリから dbt SA のメールアドレスを取得
# ---------------------------------------------------------------------------
data "terraform_remote_state" "infra" {
  backend = "gcs"

  config = {
    bucket = var.infra_state_bucket
    prefix = var.infra_state_prefix
  }
}

# ---------------------------------------------------------------------------
# BigQuery IAM
# データセットは dbt run 時に自動作成される（location は US）。
# Terraform ではプロジェクトレベルの IAM のみ管理する。
# ---------------------------------------------------------------------------

# dbt SA にプロジェクトレベルの BigQuery Job User を付与（クエリ実行に必要）
resource "google_project_iam_member" "dbt_bq_job_user" {
  project = local.config.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${data.terraform_remote_state.infra.outputs.dbt_sa_email}"
}

# dbt SA にプロジェクトレベルの BigQuery Data Editor を付与（全データセットへの読み書きに必要）
resource "google_project_iam_member" "dbt_bq_data_editor" {
  project = local.config.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${data.terraform_remote_state.infra.outputs.dbt_sa_email}"
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

  versioning {
    enabled = true
  }
}

# dbt SA にアーティファクトバケットの Object Admin 権限を付与
resource "google_storage_bucket_iam_member" "dbt_artifacts_admin" {
  bucket = google_storage_bucket.dbt_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.terraform_remote_state.infra.outputs.dbt_sa_email}"
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
}

# dbt SA に docs バケットの Object Admin 権限を付与（ドキュメントのアップロードに必要）
resource "google_storage_bucket_iam_member" "dbt_docs_admin" {
  bucket = google_storage_bucket.dbt_docs.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.terraform_remote_state.infra.outputs.dbt_sa_email}"
}
