terraform {
  # S3 バックエンドのネイティブロック（use_lockfile）は 1.10 以降で使える
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # このスタックで作るリソースすべてに付くタグ
  default_tags {
    tags = {
      Project   = var.project
      Stack     = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}
