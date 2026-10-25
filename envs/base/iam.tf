# =============================================================
# EC2 用の IAM ロール（SSM Session Manager で接続するため）
# SSH 鍵やポート 22 を開けずに、ブラウザからシェルに入れるようにする。
# 名前を aws-learn- で始めるのは、GitHub Actions のロールがこの接頭辞のロールだけ作れるため。
# =============================================================

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project}-ec2"
  description        = "EC2 role for SSM Session Manager"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-ec2"
  role = aws_iam_role.ec2.name
}
