# envs/base が作った VPC・サブネット・SG などの ID を読む
data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "envs/base/terraform.tfstate"
    region = var.region
  }
}

locals {
  base = data.terraform_remote_state.base.outputs
}

# 最新の Amazon Linux 2023 の AMI（AWS が公開している SSM パラメーターから取得）
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
