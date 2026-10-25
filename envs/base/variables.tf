variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "リソース名の接頭辞（GitHub Actions のロールは aws-learn- で始まる IAM ロールだけ作れる）"
  type        = string
  default     = "aws-learn"
}

variable "vpc_cidr" {
  description = "VPC の CIDR。/24 のサブネットを用途ごとに切り出す"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "使う AZ。キーはリソース名の末尾（a / c）に使う"
  type        = map(string)
  default = {
    a = "ap-northeast-1a"
    c = "ap-northeast-1c"
  }
}

variable "allowed_ingress_cidrs" {
  description = "ALB に HTTP で入れる送信元。自宅の IP だけにする場合は [\"x.x.x.x/32\"]"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "budget_email" {
  description = "予算アラートの通知先。GitHub の変数 BUDGET_EMAIL から TF_VAR_budget_email で渡す"
  type        = string
}

variable "monthly_budget_usd" {
  description = "月の予算（USD）"
  type        = string
  default     = "6"
}
