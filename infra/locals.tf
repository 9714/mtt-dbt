locals {
  config = var.environments[var.env]
  prefix = var.env == "prd" ? var.client_name : "${var.client_name}-${var.env}"

  # dbt seed が使用する raw データセット（dbt の raw_dataset var および sources の schema と一致させる）
  # dev/stg/prd は別 GCP プロジェクトのため、同名でもデータは完全分離される
  bq_raw_dataset = "${var.client_name}_raw"
}
