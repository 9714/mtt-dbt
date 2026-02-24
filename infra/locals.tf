locals {
  config = var.environments[var.env]
  prefix = var.env == "prd" ? var.client_name : "${var.client_name}-${var.env}"

  # dbt が使用するデータセット名（generate_schema_name と整合）
  # BigQuery はデータセットを自動作成しないため、Terraform で事前作成する
  bq_dataset_suffix = var.env == "prd" ? "" : "_${var.env}"
  bq_datasets = {
    raw     = "${var.client_name}_raw${local.bq_dataset_suffix}"
    staging = "${var.client_name}_staging${local.bq_dataset_suffix}"
    marts   = "${var.client_name}_marts${local.bq_dataset_suffix}"
  }
}
