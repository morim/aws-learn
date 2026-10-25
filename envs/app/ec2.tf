# =============================================================
# EC2 × 2（AZ ごとに 1 台、app サブネットに配置）
# - SSH 鍵なし。接続は SSM Session Manager（envs/base の aws-learn-ec2 ロール）
# - パブリック IP なし。外への通信は NAT Gateway 経由
# - 起動時の設定は user_data.sh でコード化
# =============================================================

resource "aws_instance" "app" {
  for_each = local.base.app_subnet_ids

  ami                    = data.aws_ssm_parameter.al2023.insecure_value
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [local.base.app_security_group_id]
  iam_instance_profile   = local.base.ec2_instance_profile_name

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # IMDSv2 のみ許可（メタデータ取得にトークンを必須にする）
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.project}-app-${each.key}" }

  # user_data の dnf / docker pull は NAT 経由でインターネットに出るため、経路ができてから起動する
  depends_on = [aws_route.app_to_nat]
}
