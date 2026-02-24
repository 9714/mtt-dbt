# GCP 認証不要のユニットテスト（mock_provider + plan mode）
# terraform test -verbose で実行する

mock_provider "google" {}

override_data {
  target = data.terraform_remote_state.infra
  values = {
    outputs = {
      dbt_sa_email = "dbt@mtt-dev.iam.gserviceaccount.com"
    }
  }
}

variables {
  client_name = "mtt"
  env         = "dev"

  environments = {
    dev = {
      project_id = "sandbox-nonprd"
      location   = "asia-northeast1"
    }
    stg = {
      project_id = "sandbox-nonprd"
      location   = "asia-northeast1"
    }
    prd = {
      project_id = "mtt-prd"
      location   = "asia-northeast1"
    }
  }

  infra_state_bucket = "mtt-tfstate-dev"
  infra_state_prefix = "infra"
}

# ---------------------------------------------------------------------------
# 正常系: 有効な変数でプランが通ること
# ---------------------------------------------------------------------------
run "正常系_有効な変数でプランが通ること" {
  command = plan

  assert {
    condition     = google_storage_bucket.dbt_artifacts.name == "mtt-dev-dbt-artifacts"
    error_message = "artifacts バケット名が期待値と一致しません"
  }

  assert {
    condition     = google_storage_bucket.dbt_artifacts.uniform_bucket_level_access == true
    error_message = "artifacts バケットは uniform_bucket_level_access が必要です"
  }

  assert {
    condition     = google_storage_bucket.dbt_artifacts.versioning[0].enabled == true
    error_message = "artifacts バケットはバージョニングが有効である必要があります"
  }

  assert {
    condition     = google_storage_bucket.dbt_docs.name == "mtt-dev-dbt-docs"
    error_message = "docs バケット名が期待値と一致しません"
  }

  assert {
    condition     = google_storage_bucket.dbt_docs.uniform_bucket_level_access == true
    error_message = "docs バケットは uniform_bucket_level_access が必要です"
  }

  assert {
    condition     = google_project_iam_member.dbt_bq_job_user.role == "roles/bigquery.jobUser"
    error_message = "dbt SA に bigquery.jobUser が付与されていません"
  }

  assert {
    condition     = google_project_iam_member.dbt_bq_data_editor.role == "roles/bigquery.dataEditor"
    error_message = "dbt SA に bigquery.dataEditor が付与されていません"
  }
}

# ---------------------------------------------------------------------------
# env バリデーション: 許可値以外は拒否されること
# ---------------------------------------------------------------------------
run "異常系_env_が不正な値の場合に拒否されること" {
  command = plan

  variables {
    env = "production"
  }

  expect_failures = [
    var.env,
  ]
}

# ---------------------------------------------------------------------------
# client_name バリデーション: 不正な形式は拒否されること
# ---------------------------------------------------------------------------
run "異常系_client_name_が不正な形式の場合に拒否されること" {
  command = plan

  variables {
    client_name = "Invalid_Name!"
  }

  expect_failures = [
    var.client_name,
  ]
}

# ---------------------------------------------------------------------------
# prd 環境: バケット名と project_id が prd 用になること
# ---------------------------------------------------------------------------
run "正常系_prd環境でprd用プロジェクトが使われること" {
  command = plan

  variables {
    env = "prd"
  }

  assert {
    condition     = google_storage_bucket.dbt_artifacts.name == "mtt-dbt-artifacts"
    error_message = "prd 環境のバケット名が期待値と一致しません"
  }

  assert {
    condition     = google_project_iam_member.dbt_bq_job_user.project == "mtt-prd"
    error_message = "prd 環境の project_id が正しく反映されていません"
  }
}
