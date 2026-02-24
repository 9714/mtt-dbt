locals {
  config = var.environments[var.env]
  prefix = var.env == "prd" ? var.client_name : "${var.client_name}-${var.env}"

  # dbt seed が使用する raw データセット（generate_schema_name と整合）
  # dbt seed は run より先に実行されるため、raw のみ Terraform で事前作成する
  bq_dataset_suffix = var.env == "prd" ? "" : "_${var.env}"
  bq_raw_dataset    = "${var.client_name}_raw${local.bq_dataset_suffix}"
}
