# mtt-dbt

dbt プロジェクトと、dbt に関わる GCP インフラリソース（BigQuery IAM・GCS）を一元管理するリポジトリ。

## リポジトリ構成

```
.
├── models/          # dbt モデル（staging / marts）
├── seeds/           # シードデータ
├── macros/          # マクロ
├── data-tests/      # データテスト
├── analyses/        # アドホック分析
├── infra/           # Terraform（BigQuery IAM・GCS バケット）
│   └── config.tfvars
└── .github/
    └── workflows/   # CI/CD（dbt lint・compile、Terraform test・plan・apply）
```

## 初期セットアップ

### 前提

- GCP プロジェクト（dev / stg / prd）が作成済みであること
- `gcloud` CLI がインストール済みであること
- dbt 実行用 SA はこのリポジトリの Terraform（`infra/`）で作成する

---

### Step 1: Terraform state バケットを手動作成

`terraform init` が参照するバケットは Terraform 実行前に存在が必要なため手動で作成する。

```shell
# 命名規則: {client_name}-dbt-tfstate-{env}
# dev/stg が同一プロジェクトの場合は同じ --project を指定する
gcloud storage buckets create gs://mtt-dbt-tfstate-dev \
  --project=sandbox-nonprd \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

gcloud storage buckets create gs://mtt-dbt-tfstate-stg \
  --project=sandbox-nonprd \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

gcloud storage buckets create gs://mtt-dbt-tfstate-prd \
  --project=sandbox-488413 \
  --location=asia-northeast1 \
  --uniform-bucket-level-access
```

---

### Step 2: Terraform 実行 SA + Workload Identity Federation を手動作成

GitHub Actions が GCP を操作するための SA と WIF をセットで作成する。
`{client}-infra` リポジトリのセットアップ手順に従うか、以下の権限で別途作成する。

**SA に必要な権限**

| ロール | 用途 |
|--------|------|
| `roles/bigquery.admin` | BigQuery IAM の管理 |
| `roles/storage.admin` | GCS バケット・IAM の管理 |
| `roles/resourcemanager.projectIamAdmin` | プロジェクトレベル IAM の付与 |
| `roles/iam.serviceAccountAdmin` | SA の作成・管理 |

---

### Step 3: GitHub Secrets を登録

リポジトリの Settings → Secrets and variables → Actions に以下を登録する。dev/stg と prd で別プロジェクト・別 WIF を使う場合は、prd 用に `*_PRD` の Secret を登録する。

| Secret | 説明 |
|--------|------|
| `WIF_PROVIDER` | Workload Identity Provider のリソース名（dev/stg 用） |
| `WIF_PROVIDER_PRD` | Workload Identity Provider のリソース名（prd 用） |
| `TERRAFORM_SA_EMAIL` | Terraform 実行 SA のメールアドレス（dev/stg 用） |
| `TERRAFORM_SA_EMAIL_PRD` | Terraform 実行 SA のメールアドレス（prd 用） |
| `DBT_SA_EMAIL_DEV` | dbt 実行 SA のメールアドレス（dev 用） |
| `DBT_SA_EMAIL_STG` | dbt 実行 SA のメールアドレス（stg 用） |
| `DBT_SA_EMAIL_PRD` | dbt 実行 SA のメールアドレス（prd 用） |
| `TFSTATE_BUCKET_DEV` | dev 環境の Terraform state バケット名 |
| `TFSTATE_BUCKET_STG` | stg 環境の Terraform state バケット名 |
| `TFSTATE_BUCKET_PRD` | prd 環境の Terraform state バケット名 |

---

### Step 4: `infra/config.tfvars` を編集

`client_name`・`project_id`・`wif_principal` を実際の案件・環境に合わせて書き換える。
`.tfvars` 内では変数参照は使えないため、すべてリテラルで記載する。各環境で WIF プールが別プロジェクトの場合は、`wif_principal` を環境ごとに設定する。

```hcl
client_name = "mtt"  # 案件名に変更

environments = {
  dev = {
    project_id    = "sandbox-nonprd"  # 実際の GCP プロジェクト ID
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-pool/attribute.repository/<ORG_ID>/<REPO>"
  }
  stg = {
    project_id    = "sandbox-nonprd"
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-pool/attribute.repository/<ORG_ID>/<REPO>"
  }
  prd = {
    project_id    = "sandbox-488413"
    location      = "asia-northeast1"
    wif_principal = "principalSet://iam.googleapis.com/projects/620485784254/locations/global/workloadIdentityPools/github-pool/attribute.repository/9714/mtt-dbt"
  }
}
```

---

### Step 5: 動作確認（GCP 認証不要）

変数と設定の検証を行う。`infra/tests/` に mock ユニットテストを用意している場合は `terraform test -verbose` も実行できる。

```shell
terraform -chdir=infra init -backend=false
terraform -chdir=infra validate
```

---

### Step 6: Terraform を実行（dev 環境で動作確認）

```shell
terraform -chdir=infra init \
  -backend-config="bucket=mtt-dbt-tfstate-dev" \
  -reconfigure

terraform -chdir=infra plan \
  -var-file=config.tfvars \
  -var="env=dev"

terraform -chdir=infra apply \
  -var-file=config.tfvars \
  -var="env=dev"
```

---

## 開発フロー

### ブランチ戦略

| 操作 | 対象環境 | CI/CD |
|------|----------|-------|
| `feature-*` ブランチを push | dev | PR で fmt / validate / test（mock）・plan（dev）を実行 |
| `feature-*` → `main` へマージ | stg | Terraform apply（stg）を自動実行 |
| タグ付け（例: `v1.2.3`） | prd | Terraform apply（prd）を自動実行 |

### profiles.yml のセットアップ（ローカル開発）

`profiles.yml` は gitignore されているため、`profiles.template.yml` をコピーして作成する。

```shell
cp profiles.template.yml profiles.yml
```

`profiles.yml` を編集し、以下を設定する:

| 項目 | 説明 |
|------|------|
| `project` | GCP プロジェクト ID（例: sandbox-nonprd） |
| `dataset` | 個人識別子（例: sato）。データセットが `sato_mtt_staging`, `sato_mtt_marts` のように個人別になる（[データセット命名](#データセット命名)参照） |

### データセット命名

`macros/generate_schema_name.sql` により、BigQuery のデータセット名は次の規則になる。

| 環境 | 例（staging） | 例（marts） |
|------|----------------|-------------|
| dev | `dev_mtt_staging` | `dev_mtt_marts` |
| stg | `stg_mtt_staging` | `stg_mtt_marts` |
| 個人（例: sato） | `sato_mtt_staging` | `sato_mtt_marts` |
| prd | `mtt_staging` | `mtt_marts` |

### dbt の日常開発

```shell
# パッケージインストール
dbt deps

# モデルの実行
dbt run --select <model_name>

# テスト
dbt test --select <model_name>

# コンパイル確認
dbt compile
```

### インフラ変更（GCS・BigQuery IAM）

`infra/` 以下を編集して PR を作成する。CI で fmt / validate / mock test・Terraform plan が自動実行され、plan 結果が PR コメントに表示される。
