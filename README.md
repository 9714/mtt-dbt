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
│   ├── tests/       # mock ユニットテスト（GCP 認証不要）
│   └── config.tfvars
└── .github/
    └── workflows/   # CI/CD（dbt lint・compile、Terraform test・plan・apply）
```

## 初期セットアップ

### 前提

- GCP プロジェクト（dev / stg / prd）が作成済みであること
- `{client}-infra` リポジトリで dbt SA が作成済みで、Terraform remote state に `dbt_sa_email` が出力されていること
- `gcloud` CLI がインストール済みであること

---

### Step 1: Terraform state バケットを手動作成

`terraform init` が参照するバケットは Terraform 実行前に存在が必要なため手動で作成する。

```shell
# 命名規則: {client_name}-dbt-tfstate-{env}
gcloud storage buckets create gs://mtt-dbt-tfstate-dev \
  --project=mtt-dev \
  --location=asia-northeast1 \
  --uniform-bucket-level-access

gcloud storage buckets create gs://mtt-dbt-tfstate-stg \
  --project=mtt-stg \
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

---

### Step 3: GitHub Secrets を登録

リポジトリの Settings → Secrets and variables → Actions に以下を登録する。

| Secret | 説明 |
|--------|------|
| `WIF_PROVIDER` | Workload Identity Provider のリソース名 |
| `TERRAFORM_SA_EMAIL` | Terraform 実行 SA のメールアドレス |
| `DBT_SA_EMAIL` | dbt 実行 SA のメールアドレス（CI / dev 用・WIF の service_account に使用） |
| `DBT_SA_EMAIL_STG` | dbt 実行 SA のメールアドレス（stg 用・WIF の service_account に使用） |
| `DBT_SA_EMAIL_PRD` | dbt 実行 SA のメールアドレス（prd 用・WIF の service_account に使用） |
| `TFSTATE_BUCKET_DEV` | dev 環境の Terraform state バケット名 |
| `TFSTATE_BUCKET_STG` | stg 環境の Terraform state バケット名 |
| `TFSTATE_BUCKET_PRD` | prd 環境の Terraform state バケット名 |
| `INFRA_STATE_BUCKET_DEV` | `{client}-infra` の dev state バケット名 |
| `INFRA_STATE_BUCKET_STG` | `{client}-infra` の stg state バケット名 |
| `INFRA_STATE_BUCKET_PRD` | `{client}-infra` の prd state バケット名 |

---

### Step 4: `infra/config.tfvars` を編集

`client_name`・`project_id` を実際の案件に合わせて書き換える。
`.tfvars` 内では変数参照は使えないため、すべてリテラルで記載する。

```hcl
client_name = "mtt"  # 案件名に変更

environments = {
  dev = {
    project_id = "mtt-dev"  # 実際の GCP プロジェクト ID に変更
    location   = "asia-northeast1"
  }
  stg = {
    project_id = "mtt-stg"
    location   = "asia-northeast1"
  }
  prd = {
    project_id = "sandbox-488413"
    location   = "asia-northeast1"
  }
}
```

---

### Step 5: ユニットテストで動作確認（GCP 認証不要）

mock provider を使ったユニットテストで、変数バリデーションやリソース設定を確認する。

```shell
terraform -chdir=infra init -backend=false
terraform -chdir=infra test -verbose
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
| `dataset` | 個人識別子（例: sato）。データセットが `mtt_raw_sato`, `mtt_staging_sato` のように個人別になる |

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
