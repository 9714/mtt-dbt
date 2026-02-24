# 全環境共通の設定ファイル。
# 環境の切り替えは -var "env=dev|stg|prd" で行う。

client_name = "mtt"

environments = {
  dev = {
    project_id    = "sandbox-nonprd"
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/856308617827/locations/global/workloadIdentityPools/github-pool/attribute.repository/9714/mtt-dbt"
  }
  stg = {
    project_id    = "sandbox-nonprd"
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/856308617827/locations/global/workloadIdentityPools/github-pool/attribute.repository/9714/mtt-dbt"
  }
  prd = {
    project_id    = "sandbox-488413"
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/620485784254/locations/global/workloadIdentityPools/github-pool/attribute.repository/9714/mtt-dbt"
  }
}
