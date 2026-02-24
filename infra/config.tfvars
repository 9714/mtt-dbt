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

# dbt 実行 SA のメールアドレス。
# SA は手動作成済み。CI では -var "dbt_sa_email=..." で環境ごとに上書きされる。
dbt_sa_email = "mtt-dev-dbt@sandbox-nonprd.iam.gserviceaccount.com"
