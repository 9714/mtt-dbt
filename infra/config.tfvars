# 全環境共通の設定ファイル。
# 環境の切り替えは -var "env=dev|stg|prd" で行う。

client_name = "mtt"

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

# {client}-infra の Terraform リモートステートを格納する GCS バケット。
# 手動作成済みのバケット名を指定する（CI では -var で環境ごとに上書きされる）。
infra_state_bucket = "mtt-tfstate-dev"

infra_state_prefix = "infra"
