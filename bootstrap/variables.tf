variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "リソース名の接頭辞。IAM ロールの作成許可もこの接頭辞で絞る"
  type        = string
  default     = "aws-learn"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project))
    error_message = "project は英小文字・数字・ハイフンの 3〜20 文字にしてください。"
  }
}

variable "github_owner" {
  description = "GitHub のユーザー名（または組織名）"
  type        = string
}

variable "github_repo" {
  description = "GitHub Actions を動かすリポジトリ名（オーナー部分は含めない）"
  type        = string
}

variable "github_branch" {
  description = "AWS へのデプロイを許可するブランチ"
  type        = string
  default     = "main"
}
