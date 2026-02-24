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
