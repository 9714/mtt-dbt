variable "client_name" {
  description = "リソース名のプレフィックスとなるクライアント識別子（例: acmecorp）"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,28}[a-z0-9]$", var.client_name))
    error_message = "client_name は 2〜30 文字、小文字アルファベットで始まり、小文字・数字・ハイフンのみ使用可能です。"
  }
}

variable "env" {
  description = "デプロイ環境（dev / stg / prd）"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "env は dev、stg、prd のいずれかを指定してください。"
  }
}

variable "wif_principal" {
  description = "GitHub Actions WIF の principal（例: principalSet://iam.googleapis.com/projects/.../attribute.repository/org/repo）"
  type        = string

  validation {
    condition     = can(regex("^principalSet://iam\\.googleapis\\.com/", var.wif_principal))
    error_message = "wif_principal は 'principalSet://iam.googleapis.com/' で始まる必要があります。"
  }
}

variable "environments" {
  description = "環境ごとの設定マップ"
  type = map(object({
    project_id = string
    location   = string
  }))
}
