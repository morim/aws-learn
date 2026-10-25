output "state_bucket_name" {
  description = "state 用 S3 バケット名（backend.tf に書く）"
  value       = aws_s3_bucket.tfstate.bucket
}

output "github_actions_role_arn" {
  description = "GitHub リポジトリの変数 AWS_ROLE_ARN に登録する値"
  value       = aws_iam_role.github_actions.arn
}

output "allowed_oidc_subject" {
  description = "このロールを引き受けられる GitHub Actions の実行元"
  value       = "repo:${local.github_repo}:ref:refs/heads/${var.github_branch}"
}
